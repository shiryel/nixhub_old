defmodule Core.Loader do
  @moduledoc """
    Nix context
  """

  alias Core.Nix
  alias CoreExternal.{Meilisearch, Nixpkgs, Options}

  require Logger

  def load_packages do
    load("packages", fn _index_name, version ->
      Nixpkgs.load(version)
      # TODO:
      # Meilisearch.upsert_packages(List.flatten([&1]), "INDEX_NAME")
    end)

    :ok
  end

  def load_options do
    # Load nix sources
    script = Application.app_dir(:core, "priv/nix_eval/nix_sources.sh")
    tmp = System.tmp_dir!()
    System.shell("#{script} #{tmp}")

    load("nixos_options", &Options.load_nixos/2)
    load("home_manager_options", &Options.load_home_manager/2)

    :ok
  end

  defp load(name, fun) do
    Nix.list_versions()
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
end
