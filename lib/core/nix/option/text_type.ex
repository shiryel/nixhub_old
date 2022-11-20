defmodule Core.Nix.Option.TextType do
  @moduledoc false

  use Core.Nix.Schema

  @required []
  @optional [:_type, :text]

  @primary_key false
  embedded_schema do
    field :_type, :string
    field :text, :string, default: ""
  end

  @doc false
  def changeset(%__MODULE__{} = example, attrs) do
    example
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
