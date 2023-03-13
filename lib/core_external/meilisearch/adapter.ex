defmodule CoreExternal.Meilisearch.Adapter do
  @moduledoc """
    Meilisearch API Impl
  """

  require Logger

  @behaviour CoreExternal.Meilisearch

  defp client do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, Application.get_env(:core, :meilisearch_url)},
      Tesla.Middleware.JSON
    ])
  end

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
      "proximity",
      "loc_lenght:asc",
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

  def delete_index(index_id) do
    uid = normalize(index_id)

    client()
    |> Tesla.delete("/indexes/#{uid}")
    |> results()
  end

  def upsert_packages(packages, index_id) do
    uid = normalize(index_id)

    client()
    |> Tesla.post("/indexes/#{uid}/documents", packages)
    |> results()
  end

  def index_swap(from, to) do
    client()
    |> Tesla.post("/swap-indexes", [%{indexes: [from, to]}])

    :ok
  end

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
