import Config

config :core, :nixpkgs, adapter: CoreExternal.Nixpkgs.AdapterMock
config :core, :meilisearch, adapter: CoreExternal.Meilisearch.AdapterMock

config :core,
  meilisearch_url: System.get_env("MEILISEARCH_URL", "http://localhost:7700")

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :core, Core.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "core_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :core, CoreWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "6CEplrGUYCeaR0swpc0XZw8TbbhH90IS2IeMixDy2jN5xYkiiAp6GIeLn8VtMdEG",
  server: false

# In test we don't send emails.
config :core, Core.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
