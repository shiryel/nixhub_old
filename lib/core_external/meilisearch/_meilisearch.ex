defmodule CoreExternal.Meilisearch do
  @moduledoc """
    Meilisearch API
  """

  require Logger

  @type return :: {:ok, any() | {:error, any()}}

  @callback configure(String.t()) :: return()
  @callback list_indexes() :: [uid :: String.t()]
  @callback delete_index(String.t()) :: return()
  @callback upsert_packages([Core.Nix.Package.t()], String.t()) :: return()
  @callback index_swap(String.t(), String.t()) :: :ok
  @callback search(String.t(), map()) :: return()

  defp adapter do
    Application.get_env(:core, :meilisearch)
    |> Keyword.get(:adapter)
  end

  def configure(index_id) do
    adapter().configure(index_id)
  end

  def list_indexes do
    adapter().list_indexes()
  end

  def delete_index(index_id) do
    adapter().delete_index(index_id)
  end

  def upsert_packages(packages, index_id) do
    adapter().upsert_packages(packages, index_id)
  end

  def index_swap(from, to) do
    adapter().index_swap(from, to)
  end

  def search(index_id, body) do
    adapter().search(index_id, body)
  end
end
