Mox.defmock(CoreExternal.Nixpkgs.AdapterMock, for: CoreExternal.Nixpkgs)
Mox.defmock(CoreExternal.Meilisearch.AdapterMock, for: CoreExternal.Meilisearch)

ExUnit.configure(exclude: [external: true])
ExUnit.start()
# Ecto.Adapters.SQL.Sandbox.mode(Core.Repo, :manual)
