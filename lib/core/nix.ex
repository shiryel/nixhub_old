defmodule Core.Nix do
  @moduledoc """
    Nix context
  """

  alias CoreExternal.Meilisearch
  alias Core.Nix.{Option, Package}

  require Logger

  def search_package(body) do
    with {:ok,
          %{
            "hits" => hits,
            "estimatedTotalHits" => hits_count,
            "processingTimeMs" => time
          }} <-
           Meilisearch.search("packages", body),
         results <- Enum.map(hits, &changeset/1) do
      {results, hits_count, time}
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
end
