defmodule Core.Nix do
  @moduledoc """
    Nix context
  """

  alias CoreExternal.{Meilisearch, Nixpkgs, Options}
  alias Core.Nix.{Option, Package}

  require Logger

  def list_versions do
    # the first one is the default on the search
    [
      "22.11",
      "unstable"
    ]
  end

  ##############
  # LOAD INDEX #
  ##############

  # TODO: update flake when loading
  @doc """
    Load all indexes, stable and unstable
  """
  def load_all do
    # Load nix sources
    script = Application.app_dir(:core, "priv/nix_eval/nix_sources.sh")
    tmp = System.tmp_dir!()
    System.shell("#{script} #{tmp}")

    load("nixos_options", &Options.load_nixos/2)
    load("home_manager_options", &Options.load_home_manager/2)

    load("packages", fn index_name, version ->
      Nixpkgs.load_all(%Nixpkgs{index_name: index_name, version: version})
    end)

    :ok
  end

  defp load(name, fun) do
    list_versions()
    |> Enum.each(&load(name, &1, fun))
  end

  defp load(name, version, fun) do
    index = "#{name}-#{version}"

    Logger.info("Loading index: #{index}")

    if index_exists?(index) do
      new_index = "#{index}-new"

      Meilisearch.delete_index(new_index)
      Meilisearch.configure(new_index)
      fun.(new_index, version)
      Meilisearch.index_swap(new_index, index)
    else
      Meilisearch.configure(index)
      fun.(index, version)
    end

    Logger.info("Finished loading index: #{index}")
  end

  defp index_exists?(name) do
    Meilisearch.list_indexes()
    |> Enum.any?(&(&1 == name))
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
