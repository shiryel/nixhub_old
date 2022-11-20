defmodule Core.Nix.Package do
  @moduledoc false

  use Core.Nix.Schema

  @required [
    :id,
    :loc,
    :loc_lenght,
    :version,
    :platforms
  ]

  @optional [
    :description,
    :name,
    :long_description,
    :packages,
    :outputs_to_install,
    :homepage,
    :available,
    :broken,
    :insecure,
    :unfree,
    :unsupported,
    :position
  ]

  embedded_schema do
    field :__type__, :string, default: "package"
    field :loc, {:array, :string}
    field :loc_lenght, :integer
    field :version, :string
    field :available, :boolean
    field :broken, :boolean
    field :description, :string
    field :long_description, :string
    field :homepage, {:array, :string}
    field :insecure, :boolean
    field :name, :string
    field :outputs_to_install, {:array, :string}
    field :packages, :string
    field :platforms, {:array, :string}
    field :position, :string
    field :unfree, :boolean
    field :unsupported, :boolean

    embeds_many :licenses, __MODULE__.License
    embeds_many :maintainers, __MODULE__.Maintainer
  end

  @doc false
  def changeset(%__MODULE__{} = package, attrs) do
    package
    |> cast(attrs, @required ++ @optional)
    |> cast_embed(:licenses)
    |> cast_embed(:maintainers)
    |> validate_required(@required)
  end

  def create_changeset(%__MODULE__{} = package, attrs) do
    package
    |> cast(attrs, @required ++ @optional)
    |> id()
    |> loc_lenght()
    |> position()
    |> cast_embed(:licenses)
    |> cast_embed(:maintainers)
    |> validate_required(@required)
  end

  # ID

  defp id(%{valid?: true, changes: %{loc: loc}} = changeset) do
    id =
      ["package" | loc]
      |> Enum.join("___")
      # Meilisearch does not accepts dots
      # |> String.replace(".", "_")
      |> String.replace(~r|[^0-9a-zA-Z_-]|, "_")

    put_change(changeset, :id, id)
  end

  defp id(changeset), do: changeset

  # LOC LENGHT

  defp loc_lenght(%{valid?: true, changes: %{loc: loc}} = changeset) do
    put_change(changeset, :loc_lenght, length(loc))
  end

  defp loc_lenght(changeset), do: changeset

  # POSITION

  defp position(%{valid?: true, changes: %{position: p}} = changeset)
       when is_binary(p) do
    [_, raw_p] = String.split(p, "-source/", parts: 2)
    position = String.replace(raw_p, ":", "#L")

    put_change(changeset, :position, position)
  end

  defp position(changeset), do: changeset
end
