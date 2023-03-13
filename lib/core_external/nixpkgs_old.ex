defmodule CoreExternal.NixpkgsOld do
  @moduledoc """
    Loads nixpkgs on Meilisearch in batches
  """

  defstruct index_name: "packages_stable",
            version: "stable",
            start: 0,
            attr_path: ["pkgs"],
            empty_stage: 0

  require Logger

  alias Core.Nix.Package
  alias CoreExternal.Meilisearch
  alias CoreExternal.Utils

  require Logger

  ##########
  # LOADER #
  ##########

  def load_all(%__MODULE__{
        index_name: index_name,
        start: start,
        attr_path: attr_path,
        empty_stage: 10
      }) do
    Logger.info("""
      Finished loading packages
      INDEX NAME: #{index_name}
      Last stage: #{start} | Path: #{inspect(attr_path)}
    """)

    :ok
  end

  def load_all(%__MODULE__{} = config) do
    # Avoid deep packages to avoid infinite recursions
    if length(config.attr_path) > 3 do
      :ok
    else
      case get_super_packages_path(config) do
        [] ->
          load_all(%{
            config
            | start: config.start + 1,
              empty_stage: config.empty_stage + 1
          })

        new_packages ->
          new_packages
          |> List.flatten()
          |> Meilisearch.upsert_packages(config.index_name)

          load_all(%{
            config
            | start: config.start + 1
          })
      end
    end

    # Avoids the usage of a incomplete index
    # by deleting the index itself
  rescue
    _ ->
      Meilisearch.delete_index(config.index_name)
      :ok
  end

  defp get_super_packages_path(config) do
    # Logger.info("Getting packages - Stage: #{config.start} | Path: #{inspect(config.attr_path)}")
    load_params(config)

    nix_eval = Application.app_dir(:core, "priv/nix_eval")

    System.shell(
      "nix --experimental-features 'nix-command flakes' eval --raw path:#{nix_eval}#getSuperPackagesPath"
    )
    |> elem(0)
    |> Jason.decode()
    |> case do
      {:ok, []} ->
        get_packages_meta(config)

      {:ok, r} ->
        # Load children
        Enum.each(r, fn %{"r" => path} ->
          load_all(%{config | start: 0, attr_path: path})
        end)

        get_packages_meta(config)
    end
  end

  defp get_packages_meta(config) do
    load_params(config)

    nix_eval = Application.app_dir(:core, "priv/nix_eval")

    System.shell(
      "nix --experimental-features 'nix-command flakes' eval --raw path:#{nix_eval}#getPackagesMeta"
    )
    |> elem(0)
    |> decode()
  end

  defp load_params(%{version: version, start: start, attr_path: attr_path}) do
    attr_path =
      Enum.reduce(attr_path, "[", fn
        x, acc ->
          acc <> ~s| "| <> x <> ~s|" |
      end) <> "]"

    nix_eval = Application.app_dir(:core, "priv/nix_eval")

    System.shell(
      ~s|echo '{  version = "#{version}"; offset = #{start}; size = 200; attr_path = #{attr_path}; }' > #{nix_eval}/params.nix|
    )
  end

  ##########
  # PARSER #
  ##########

  defp decode(json) do
    case Jason.decode(json) do
      {:ok, result} ->
        result
        |> Enum.filter(fn
          # rejects anything that does not have a platform
          # as those usually are not usable packages
          # like nix's build-blocks or nix's tests
          x -> Map.has_key?(x["meta"], "platforms")
        end)
        |> Enum.map(fn
          %{
            "meta" => meta,
            "version" => version,
            "path" => [_pkgs | attr_path]
          } ->
            package =
              meta
              |> Utils.normalize_map()
              |> Map.merge(%{
                "name" => Enum.join(attr_path, "."),
                "version" => version,
                "loc" => attr_path
              })

            Package.create_changeset(%Package{}, package)
            |> Ecto.Changeset.apply_action!(:insert)
        end)

      {:error, error} ->
        Logger.error("""
          ERROR: #{inspect(error)}
          JSON: #{inspect(json)}
        """)

        []
    end
  end
end
