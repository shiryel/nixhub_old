IO.puts("""
========== UTILS ============
Utils.load_meilisearch - Loads all nixpkgs/options to Meilisearch
=============================
""")

defmodule Utils do
  alias CoreExternal.{Meilisearch, Nixpkgs, Options}

  def load_meilisearch do
    Meilisearch.delete_index("packages")
    Meilisearch.configure("packages")
    Options.load_nixos()
    Options.load_home_manager()
    Nixpkgs.load_all()
  end
end
