defmodule CoreExternal.Options do
  @moduledoc """
    Loads Nixos & HomeManager options on Meilisearch
  """

  alias Core.Nix.Option
  alias CoreExternal.{Meilisearch, Utils}

  def load_nixos do
    File.read!("tmp/nixos_options.json")
    |> Jason.decode!()
    |> Enum.map(fn {k, v} ->
      option =
        Map.put(v, "name", k)
        |> normalize_option()

      Option.create_changeset(%Option{__type__: "nixos_option"}, option)
      |> Ecto.Changeset.apply_action!(:insert)
    end)
    |> List.flatten()
    |> Meilisearch.upsert_packages()
  end

  def load_home_manager do
    System.shell("nix eval --raw ./eval#getHomeManagerOptions")
    |> elem(0)
    |> Jason.decode!()
    |> Enum.map(fn {k, v} ->
      Map.put(v, "name", k)
      |> normalize_home_manager()
    end)
    |> List.flatten()
    |> Meilisearch.upsert_packages()
  end

  defp normalize_home_manager(map) do
    map
    |> normalize_option()
    |> Enum.map(fn
      {"declarations", declarations} ->
        Enum.map(declarations, fn
          %{"path" => path} ->
            path

          path ->
            path
        end)
        |> then(&{"declarations", &1})

      {"description", %{"_type" => _type, "text" => text}} ->
        {"description", text}

      option ->
        option
    end)
    |> Map.new()
    |> then(
      &Option.create_changeset(
        %Option{__type__: "home_manager_option"},
        &1
      )
    )
    |> Ecto.Changeset.apply_action!(:insert)
  end

  defp normalize_option(option) do
    option
    |> Utils.normalize_map()
    |> Enum.map(fn
      {_any, %{"_type" => "literalExpression", "text" => _text}} = option ->
        # Maybe format with nixpkgs-fmt ?
        option

      {key, text} when key in ["example", "default"] ->
        {key,
         %{
           "_type" => nil,
           "text" => Jason.encode!(text) |> Jason.Formatter.pretty_print()
         }}

      option ->
        option
    end)
    |> Map.new()
  end
end
