defmodule Core.Nix.Derivation do
  @moduledoc false

  use Core.Nix.Schema

  @required [
    :drv_path,
    :is_cached
  ]

  @optional [
    :description,
    :long_description,
    :available,
    :broken,
    :insecure,
    :unfree,
    :unsupported,
    :homepage,
    :outputs_to_install,
    :platforms
  ]

  @primary_key {:drv_path, :string, autogenerate: false}
  schema "derivations" do
    field :description, :string
    field :long_description, :string
    field :is_cached, :boolean
    field :available, :boolean
    field :broken, :boolean
    field :insecure, :boolean
    field :unfree, :boolean
    field :unsupported, :boolean
    field :homepage, {:array, :string}
    field :outputs_to_install, {:array, :string}
    field :platforms, {:array, :string}

    has_many :packages, Core.Nix.Package

    many_to_many :licenses, __MODULE__.License,
      join_through: "derivations_licenses",
      join_keys: [derivation_id: :drv_path, license_id: :spdx_id]

    many_to_many :maintainers, __MODULE__.Maintainer,
      join_through: "derivations_maintainers",
      join_keys: [derivation_id: :drv_path, maintainer_id: :github_id]

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = package, attrs) do
    package
    |> cast(attrs, @required ++ @optional)
    |> cast_assoc(:licenses)
    |> cast_assoc(:maintainers)
    |> position()
    |> validate_required(@required)

    # |> unique_constraint([:drv_path, :position])
  end

  # POSITION

  defp position(%{valid?: true, changes: %{position: p}} = changeset)
       when is_binary(p) do
    position =
      case String.split(p, "-source/", parts: 2) do
        [_, raw_p] ->
          String.replace(raw_p, ":", "#L")

        _ ->
          p
      end

    put_change(changeset, :position, position)
  end

  defp position(changeset), do: changeset
end
