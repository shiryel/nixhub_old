defmodule Core.Nix.Option do
  @moduledoc false

  use Core.Nix.Schema

  require Logger

  @required [
    :__type__,
    :id,
    :name,
    :declarations,
    :loc,
    :loc_lenght,
    :read_only,
    :type
  ]

  @optional [
    :description
  ]

  embedded_schema do
    field :__type__, :string
    field :name, :string
    field :declarations, {:array, :string}
    field :description, :string
    field :loc, {:array, :string}
    field :loc_lenght, :integer
    field :read_only, :boolean
    field :type, :string

    embeds_one :example, __MODULE__.TextType
    embeds_one :default, __MODULE__.TextType
  end

  @doc false
  def changeset(%__MODULE__{} = nixos_option, attrs) do
    nixos_option
    |> cast(attrs, @required ++ @optional)
    |> cast_embed(:example)
    |> cast_embed(:default)
    |> validate_required(@required)
  end

  @doc false
  def create_changeset(%__MODULE__{} = nixos_option, attrs) do
    nixos_option
    |> cast(attrs, @required ++ @optional)
    |> id()
    |> loc_lenght()
    |> description()
    |> cast_embed(:example)
    |> cast_embed(:default)
    |> validate_required(@required)
  end

  # ID

  defp id(%{valid?: true, changes: %{name: name}} = changeset) do
    # Meilisearch does not accepts dots
    id = "nixos_option___" <> String.replace(name, ~r|[^0-9a-zA-Z_-]|, "_")

    put_change(changeset, :id, id)
  end

  defp id(changeset), do: changeset

  # LOC LENGHT

  defp loc_lenght(%{valid?: true, changes: %{loc: loc}} = changeset) do
    put_change(changeset, :loc_lenght, length(loc))
  end

  defp loc_lenght(changeset), do: changeset

  # DESCRIPTION

  defp description(%{valid?: true, changes: %{description: description}} = changeset) do
    regex =
      ~r[(<(literal|literallayout|replaceable|filename|code|option|command|package|emphasis|citerefentry|refentrytitle|manvolnum)>|<link xlink:href="(.+?)" ?/>|<link xlink:href="(.+?)">)]

    new_description =
      if String.match?(description, regex) do
        parse_docbook_to_html(description)
      else
        description
      end

    put_change(changeset, :description, new_description)
  end

  defp description(changeset), do: changeset

  defp parse_docbook_to_html(description) do
    unless File.dir?("tmp/"), do: File.mkdir("tmp")

    file = "tmp/#{:rand.bytes(32) |> Base.url_encode64()}"
    File.write(file, "<para>" <> description <> "</para>")

    result =
      case System.cmd(
             "pandoc",
             [file, "--from=docbook", "--to=html"],
             stderr_to_stdout: false,
             parallelism: true
           ) do
        {result, 0} ->
          result

        _error ->
          Logger.error("""
          Could not parse: 
          #{inspect(description)}
          """)

          description
      end

    File.rm(file)
    result
  end
end
