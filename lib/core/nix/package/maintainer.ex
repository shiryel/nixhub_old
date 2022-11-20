defmodule Core.Nix.Package.Maintainer do
  @moduledoc false

  use Core.Nix.Schema

  @required [
    :email,
    :name
  ]

  @optional [
    :github,
    :github_id,
    :matrix
  ]

  @primary_key false
  embedded_schema do
    field :email, :string
    field :github, :string
    field :github_id, :integer
    field :name, :string
    field :matrix, :string
  end

  @doc false
  def changeset(%__MODULE__{} = maintainer, attrs) do
    maintainer
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
