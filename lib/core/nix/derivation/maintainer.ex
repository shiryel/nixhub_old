defmodule Core.Nix.Derivation.Maintainer do
  @moduledoc false

  use Core.Nix.Schema

  @required [
    :name,
    :github_id
  ]

  @optional [
    :github,
    :email,
    :matrix
  ]

  @primary_key {:github_id, :integer, autogenerate: false}
  schema "maintainers" do
    field :email, :string
    field :github, :string
    field :name, :string
    field :matrix, :string

    many_to_many :derivations, Core.Nix.Derivation,
      join_through: "derivations_maintainers",
      join_keys: [license_id: :github_id, derivation_id: :drv_path]

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = maintainer, attrs) do
    maintainer
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
