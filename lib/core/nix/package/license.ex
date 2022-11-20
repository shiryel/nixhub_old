defmodule Core.Nix.Package.License do
  @moduledoc false

  use Core.Nix.Schema

  @required []

  @optional [
    :deprecated,
    :free,
    :redistributable,
    :full_name,
    :short_name,
    :spdx_id,
    :url
  ]

  @primary_key false
  embedded_schema do
    field :deprecated, :boolean
    field :free, :boolean
    field :full_name, :string
    field :redistributable, :boolean
    field :short_name, :string
    field :spdx_id, :string
    field :url, :string
  end

  @doc false
  def changeset(%__MODULE__{} = license, [x | _]) when is_binary(x) do
    changeset(license, %{license: %{url: x}})
  end

  def changeset(%__MODULE__{} = license, attrs) do
    license
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end
end
