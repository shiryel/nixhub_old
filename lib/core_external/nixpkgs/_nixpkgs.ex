defmodule CoreExternal.Nixpkgs do
  @moduledoc """
    Loads nixpkgs on Meilisearch in batches
  """

  alias Core.Nix
  alias Core.Nix.Package.Version
  alias CoreExternal.Utils

  require Logger

  @callback eval(String.t()) :: [String.t()] | File.Stream.t()

  defp adapter do
    Application.get_env(:core, :nixpkgs)
    |> Keyword.get(:adapter)
  end

  @spec load(Version.t()) :: :ok
  def load(version) do
    adapter().eval(version)
    |> Stream.map(&parse_one/1)
    |> Stream.reject(&(&1 == nil))
    |> Stream.map(&Map.merge(&1, %{"version_id" => version.id, "derivation" => &1}))
    |> Enum.each(fn x ->
      Nix.upsert_package(x)
    end)
  end

  def parse_one(json) do
    with {:ok, %{"meta" => meta} = valid_json} when is_map(meta) <- Jason.decode(json) do
      valid_json
      |> Utils.normalize_map()
      |> then(&Map.merge(&1, meta))
      |> Map.new(fn
        # NOTE: those are not on the changeset because they are a different type

        # remove maintainers that don't have github_id because of relational DB suffering limitations
        {"maintainers", m} ->
          {"maintainers", Enum.filter(m, &Map.has_key?(&1, "github_id"))}

        # sometimes homepage will be a name only
        {"homepage", v} ->
          {"homepage", List.flatten([v])}

        # sometimes platforms will be
        # [%{"abi" => %{"_type" => "abi", "float" => "soft", "name" => "gnueabi"}}]
        {"platforms", [%{"abi" => %{"name" => _}} | _] = v} ->
          {"platforms", Enum.map(v, & &1["abi"]["name"])}

        {k, v} ->
          {k, v}
      end)

      # |> then(&Package.create_changeset(%Package{}, &1))
      # |> Ecto.Changeset.apply_action!(:insert)
    else
      error ->
        Logger.warn("""
          ERROR: #{inspect(error)}
          JSON: #{inspect(json)}
        """)

        # needs to be nil to be rejected
        nil
    end
  end
end
