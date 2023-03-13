defmodule Core.NixTest do
  use Core.DataCase, async: true

  alias Core.Repo
  alias Core.Nix
  alias Core.Nix.{Derivation, Package}
  alias Core.Nix.Derivation.{License, Maintainer}

  describe "upsert_package/1" do
    test """
      INSERT PACKAGE
      when:
      - not inserted
      do:
      - create pacakge
      - create derivation
      - create licenses
      - create maintainers
    """ do
      version = insert(:version)
      params =
        params_for(:package)
        |> Map.merge(%{derivation: params_for(:derivation, is_cached: true)})
        |> Map.merge(%{version_id: version.id})

      assert {:ok,
              %{
                maybe_get_package: nil,
                maybe_upsert_package: %Package{} = package
              }} = Nix.upsert_package(params)

      result = Repo.preload(package, [derivation: [:licenses, :maintainers]])

      assert %Package{derivation: derivation} = result
      assert %Derivation{is_cached: true, licenses: licenses, maintainers: maintainers} = derivation
      assert [%License{}] = licenses
      assert [%Maintainer{}] = maintainers
    end

    test """
      INSERT NEW ALIAS
      when:
      - package and assocs already exists
      do:
      - update package `attr_aliases`
      - update package `attr` based on length
    """ do
      version = insert(:version)

      insert(:package,
        name: "elixir",
        position: "/pkgs/elixir",
        attr: "small.elixir",
        version: version
      )

      params_1 =
        params_for(:package, name: "elixir", position: "/pkgs/elixir", attr: "variation.elixir")
        |> Map.merge(params_for(:derivation))
        |> Map.merge(%{version_id: version.id})

      assert {:ok,
              %{
                maybe_get_package: %Package{},
                maybe_upsert_package: %Package{
                  attr: "small.elixir",
                  attr_aliases: ["variation.elixir"]
                }
              }} = Nix.upsert_package(params_1)

      params_2 =
        params_for(:package, name: "elixir", position: "/pkgs/elixir", attr: "elixir")
        |> Map.merge(params_for(:derivation))
        |> Map.merge(%{version_id: version.id})

      assert {:ok,
              %{
                maybe_get_package: %Package{},
                maybe_upsert_package: %Package{
                  attr: "elixir",
                  attr_aliases: ["small.elixir", "variation.elixir"]
                }
              }} = Nix.upsert_package(params_2)
    end

    test """
      UPDATE DERIVATION
      when:
      - package and assocs already exists
      do:
      - update only changed fields, like `is_cached`
    """ do
      attrs = [name: "elixir", position: "/pkgs/elixir", attr: "elixir"]

      version = insert(:version)
      derivation = build(:derivation, is_cached: false)
      insert(:package, [derivation: derivation, version: version] ++ attrs)

      params = 
        params_for(:package, attrs)
        |> Map.merge(%{derivation: params_for(:derivation, is_cached: true)})
        |> Map.merge(%{version_id: version.id})

      assert {:ok,
              %{
                maybe_get_package: %Package{},
                maybe_upsert_package: %Package{} = package
              }} = Nix.upsert_package(params)

      result = Repo.preload(package, [derivation: [:licenses, :maintainers]])

      assert %Package{derivation: derivation} = result
      assert %Derivation{is_cached: true, licenses: licenses, maintainers: maintainers} = derivation
      assert [%License{}] = licenses
      assert [%Maintainer{}] = maintainers
    end

    test """
      INSERT SAME PACKAGE 2 TIMES
      when:
      - not inserted
      do:
      - respect unique_constraint
    """ do
      attrs = [name: "a", position: "a", attr: "a", attr_path: ["a"]]

      version = insert(:version)

      params =
        params_for(:package, attrs)
        |> Map.merge(params_for(:derivation, is_cached: true))
        |> Map.merge(%{version_id: version.id})

      assert {:ok,
              %{
                maybe_get_package: nil,
                maybe_upsert_package: %Package{} 
              }} = Nix.upsert_package(params)

      assert {:ok,
              %{
                maybe_get_package: %Package{},
                maybe_upsert_package: %Package{}
              }} = Nix.upsert_package(params)
    end
  end
end
