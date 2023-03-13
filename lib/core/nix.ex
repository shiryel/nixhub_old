defmodule Core.Nix do
  @moduledoc """
    Nix Context
  """

  import Ecto.Query, warn: false

  require Logger

  alias Core.Repo
  alias Ecto.Multi

  alias Core.Nix.{Option, Package, Version}
  alias CoreExternal.Meilisearch

  def list_versions do
    from(v in Version)
    |> Repo.all()
  end

  ###########
  # NIXPKGS #
  ###########

  def count_packages do
    from(p in Package, select: count())
    |> Repo.one()
  end

  # NOTE: this code expects that packages with `is_cached: true` will
  #       be stored first than their variations
  def upsert_package(attrs \\ %{}) do
    Multi.new()
    |> Multi.run(:params, fn _, _ -> {:ok, attrs} end)
    |> Multi.run(:package_changeset, fn _, _ ->
      {:ok, Package.create_changeset(%Package{}, attrs)}
    end)
    |> Multi.run(:maybe_get_package, &maybe_get_package/2)
    |> Multi.run(:maybe_upsert_package, &maybe_upsert_package/2)
    |> Repo.transaction()
  end

  defp maybe_get_package(_repo, %{package_changeset: %{valid?: true, changes: c}}) do
    Repo.get_by(Package,
      name: c.name,
      position: c.position,
      version_id: c.version_id
    )
    |> Repo.preload(derivation: [:licenses, :maintainers])
    |> then(&{:ok, &1})
  end

  defp maybe_get_package(_repo, %{package_changeset: changeset}) do
    Logger.error("""
      Invalid changeset:
      #{inspect(changeset, pretty: true)}
    """)

    {:error, :invalid_changeset}
  end

  # insert package
  defp maybe_upsert_package(_repo, %{
         package_changeset: changeset,
         maybe_get_package: nil
       }) do
    Repo.insert(changeset)
  end

  # update package
  defp maybe_upsert_package(_repo, %{
         params: params,
         package_changeset: %{changes: %{attr: new_attr}},
         maybe_get_package:
           %Package{
             attr: old_attr,
             attr_path: old_attr_path,
             attr_aliases: attr_aliases
           } = package
       }) do
    cond do
      new_attr == old_attr ->
        Package.create_changeset(package, params)
        |> Repo.update(force: true)

      String.length(new_attr) > String.length(old_attr) ->
        new_aliases = [new_attr | attr_aliases] |> Enum.uniq()

        Package.create_changeset(package, params)
        |> Ecto.Changeset.change(%{
          attr: old_attr,
          attr_path: old_attr_path,
          attr_aliases: new_aliases
        })
        |> Repo.update(force: true)

      true ->
        new_aliases = [old_attr | attr_aliases] |> Enum.uniq()

        Package.create_changeset(package, params)
        |> Ecto.Changeset.change(%{attr_aliases: new_aliases})
        |> Repo.update(force: true)
    end
  end

  ################
  # SEARCH INDEX #
  ################

  def search_package(body, type, version) do
    with {:ok,
          %{
            "hits" => hits,
            "estimatedTotalHits" => hit_count,
            "processingTimeMs" => time
          }} <-
           Meilisearch.search("#{type}-#{version}", body),
         results <- Enum.map(hits, &changeset/1) do
      %{hits: results, hit_count: hit_count, time: time}
    end
  end

  defp changeset(%{"__type__" => "package"} = map) do
    Package.changeset(%Package{}, map)
    |> Ecto.Changeset.apply_action!(:insert)
  end

  defp changeset(%{"__type__" => type} = map)
       when type in ["nixos_option", "home_manager_option"] do
    Option.changeset(%Option{}, map)
    |> Ecto.Changeset.apply_action!(:insert)
  end

  defp changeset(map) do
    map
  end
end
