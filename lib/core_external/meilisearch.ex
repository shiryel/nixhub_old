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
  def configure(uid \\ "packages") do
    client = client()

    Tesla.post(client, "/indexes", %{uid: uid, primaryKey: "id"})
    |> results()

    Tesla.put(client, "/indexes/#{uid}/settings/filterable-attributes", [
      "__type__",
      "loc",
      "loc_lenght"
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

  @spec delete_index(String.t()) :: return()
  def delete_index(uid) do
    client()
    |> Tesla.delete("/indexes/#{uid}")
    |> results()
  end

  @spec upsert_packages([Core.Nix.Package.t()]) :: return()
  def upsert_packages(packages) do
    client()
    |> Tesla.post("/indexes/packages/documents", packages)
    |> results()
  end

  @spec search(String.t(), map()) :: return()
  def search(index_id, body) do
    client()
    |> Tesla.post("/indexes/#{index_id}/search", body)
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
end
