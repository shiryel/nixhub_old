defmodule CoreExternal.Nixpkgs do
  @moduledoc """
    Loads nixpkgs on Meilisearch in batches
  """

  require Logger

  alias Core.Nix.Package
  alias CoreExternal.Meilisearch
  alias CoreExternal.Utils

  require Logger

  ##########
  # LOADER #
  ##########

  def load_all(start \\ 0, start_of \\ ["pkgs"], empty_stage \\ 0)

  def load_all(start, start_of, 10) do
    Logger.info("""
      Finished loading packages
      Last stage: #{start} | Path: #{inspect(start_of)}
    """)

    :ok
  end

  def load_all(start, start_of, empty_stage) do
    # Avoid deep packages to avoid infinite recursions
    if length(start_of) > 3 do
      :ok
    else
      case get_super_packages_path(start, start_of) do
        [] ->
          load_all(start + 1, start_of, empty_stage + 1)

        new_packages ->
          new_packages
          |> List.flatten()
          |> Meilisearch.upsert_packages()

          load_all(start + 1, start_of)
      end
    end
  end

  defp get_super_packages_path(start, start_of) do
    Logger.info("Getting packages - Stage: #{start} | Path: #{inspect(start_of)}")
    load_params(start, start_of)

    System.shell("nix eval --raw ./eval#getSuperPackagesPath")
    |> elem(0)
    |> Jason.decode()
    |> case do
      {:ok, []} ->
        get_packages_meta(start, start_of)

      {:ok, r} ->
        # Load children
        Enum.each(r, fn %{"r" => path} ->
          load_all(0, path)
        end)

        get_packages_meta(start, start_of)
    end
  end

  defp get_packages_meta(start, start_of) do
    load_params(start, start_of)

    System.shell("nix eval --raw ./eval#getPackagesMeta")
    |> elem(0)
    |> decode()
  end

  defp load_params(start, start_of) do
    start_of =
      Enum.reduce(start_of, "[", fn
        x, acc ->
          acc <> ~s| "| <> x <> ~s|" |
      end) <> "]"

    System.shell("echo '{ start = #{start}; start_of = #{start_of}; }' > eval/params.nix")
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
        Logger.warn(inspect(error))
        []
    end
  end
end
