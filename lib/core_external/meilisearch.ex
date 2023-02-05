defmodule CoreExternal.Meilisearch do
  @moduledoc """
    Meilisearch API
  """

  require Logger

  @type return :: {:ok, any() | {:error, any()}}

  defp client do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, Application.get_env(:core, :meilisearch_url)},
      Tesla.Middleware.JSON
    ])
  end

  @spec configure(String.t()) :: return()
  def configure(index_id) do
    client = client()
    uid = normalize(index_id)

    Tesla.post(client, "/indexes", %{uid: uid, primaryKey: "id"})
    |> results()

    Tesla.put(client, "/indexes/#{uid}/settings/filterable-attributes", [
      "id",
      "loc",
      "loc_lenght"
    ])
    |> results()

    Tesla.put(client, "/indexes/#{uid}/settings/ranking-rules", [
      "words",
      "typo",
      "loc_lenght:asc",
      "proximity",
      "attribute",
      "sort",
      "exactness"
    ])
    |> results()

    Tesla.put(client, "/indexes/#{uid}/settings/searchable-attributes", [
      "name",
      "version",
      "loc",
      "description",
      "long_description"
    ])
    |> results()
  end

  @spec list_indexes() :: [uid :: String.t()]
  def list_indexes do
    client()
    |> Tesla.get("/indexes")
    |> case do
      {:ok, %{status: s, body: %{"results" => results}}} when s < 300 ->
        results
        |> Enum.map(& &1["uid"])

      _ ->
        []
    end
  end

  @spec delete_index(String.t()) :: return()
  def delete_index(index_id) do
    uid = normalize(index_id)

    client()
    |> Tesla.delete("/indexes/#{uid}")
    |> results()
  end

  @spec upsert_packages([Core.Nix.Package.t()], String.t()) :: return()
  def upsert_packages(packages, index_id) do
    uid = normalize(index_id)

    client()
    |> Tesla.post("/indexes/#{uid}/documents", packages)
    |> results()
  end

  @spec index_swap(from :: String.t(), to :: String.t()) :: :ok
  def index_swap(from, to) do
    client()
    |> Tesla.post("/swap-indexes", [%{indexes: [from, to]}])

    :ok
  end

  @spec search(String.t(), map()) :: return()
  def search(index_id, body) do
    uid = normalize(index_id)

    client()
    |> Tesla.post("/indexes/#{uid}/search", body)
    |> results()
  end

  defp results(response) do
    case response do
      {:ok, %{status: s, body: results}} when s < 300 ->
        {:ok, results}

      err ->
        Logger.error(inspect(err, pretty: true))
        {:error, err}
    end
  end

  # https://docs.meilisearch.com/learn/core_concepts/indexes.html#index-uid
  defp normalize(uid) do
    uid
    |> String.downcase()
    |> String.replace(~r|[^a-zA-Z0-9_-]+|, "_")
  end
end
