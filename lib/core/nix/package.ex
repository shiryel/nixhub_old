defmodule Core.Nix.Package do
  @moduledoc false

  use Core.Nix.Schema

  @required [
    :attr,
    :attr_path,
    :name,
    :position
  ]

  @optional [
    # required to load the association when creating from attr
    :version_id
  ]

  schema "packages" do
    field :name, :string
    field :position, :string
    field :attr, :string
    field :attr_path, {:array, :string}
    field :attr_aliases, {:array, :string}, default: []

    belongs_to :version, Core.Nix.Version
    belongs_to :derivation, Core.Nix.Derivation, references: :drv_path, type: :string

    timestamps()
  end

  @doc false
  def changeset(%__MODULE__{} = package, attrs) do
    package
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
  end

  def create_changeset(%__MODULE__{} = package, attrs) do
    package
    |> cast(attrs, @required ++ @optional)
    |> cast_assoc(:version)
    |> cast_assoc(:derivation)
    |> position()
    |> validate_required(@required)

    # |> unique_constraint([:name, :position])
  end

  # ATTR PATH LENGHT

  # defp attr_path_lenght(%{valid?: true, changes: %{attr_path: attr_path}} = changeset) do
  #  put_change(changeset, :attr_path_lenght, length(attr_path))
  # end

  # defp attr_path_lenght(changeset), do: changeset

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
