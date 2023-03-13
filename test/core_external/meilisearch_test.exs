defmodule CoreExternal.MeilisearchTest do
  use Core.DataCase, async: true

  alias CoreExternal.Meilisearch

  @tag :external
  test "Can insert a index" do
    meilisearch_config = Application.get_env(:core, :meilisearch)
    Application.put_env(:core, :meilisearch, adapter: CoreExternal.Meilisearch.Adapter)
    Meilisearch.configure("test")
    Meilisearch.upsert_packages([%{test: "test"}], "test")
    Application.put_env(:core, :meilisearch, meilisearch_config)
  end
end
