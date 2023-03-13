defmodule Core.Nix.Version do
  @moduledoc false

  use Core.Nix.Schema

  schema "versions" do
    field :name, :string
    field :repo, :string
    field :branch, :string

    has_many :packages, Core.Nix.Package

    timestamps()
  end
end
