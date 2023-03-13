defmodule CoreExternal.NixpkgsTest do
  use Core.DataCase, async: true

  alias Core.Nix
  alias Core.Nix.Version
  alias CoreExternal.Nixpkgs

  describe "load_version/1" do
    test "Can parse many packages" do
      expect(Nixpkgs.AdapterMock, :eval, fn %Version{} ->
        File.stream!("test/support/fixtures/packages.json", [], :line)
      end)

      version = insert(:version)

      assert :ok == Nixpkgs.load(version)
      assert 10 == Nix.count_packages()
    end
  end

  describe "parse_one/1" do
    test "Can parse one package" do
      result =
        File.read!("test/support/fixtures/package.json")
        |> Nixpkgs.parse_one()

      assert %{"attr" => _} = result
    end
  end
end
