defmodule Core.Nix.Derivation.License do
  @moduledoc false

  use Core.Nix.Schema

  @required [
    :spdx_id
  ]

  @optional [
    :deprecated,
    :free,
    :redistributable,
    :full_name,
    :short_name,
    :url
  ]

  @primary_key {:spdx_id, :string, autogenerate: false}
  schema "licenses" do
    field :deprecated, :boolean
    field :free, :boolean
    field :full_name, :string
    field :redistributable, :boolean
    field :short_name, :string
    field :url, :string

    many_to_many :packages, Core.Nix.Package,
      join_through: "derivations_licenses",
      join_keys: [license_id: :spdx_id, package_id: :drv_path]

    timestamps()
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
