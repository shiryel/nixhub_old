defmodule CoreExternal.Nixpkgs.AdapterLocalCache do
  @doc """
    Gets the cached result, for local testing
  """

  require Logger

  @behaviour CoreExternal.Nixpkgs

  @impl true
  def eval(_version) do
    Logger.info("""
      Loading packages from "packages.json" file
      NOTE THAT ALL VERSIONS WILL BE THE SAME
    """)

    File.stream!("packages_sorted.json")
  end
end
