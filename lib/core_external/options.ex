defmodule CoreExternal.Options do
  @moduledoc """
    Loads Nixos & HomeManager options on Meilisearch
  """

  alias Core.Nix.Option
  alias CoreExternal.{Meilisearch, Utils}

  def load_nixos(index_name, version) do
    (System.tmp_dir!() <> "/results/nixos_#{version}/share/doc/nixos/options.json")
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn {k, v} ->
      option =
        Map.put(v, "name", k)
        |> normalize_option()

      Option.create_changeset(%Option{__type__: "nixos_option"}, option)
      |> Ecto.Changeset.apply_action!(:insert)
    end)
    |> List.flatten()
    |> Meilisearch.upsert_packages(index_name)
  end

  def load_home_manager(index_name, version) do
    (System.tmp_dir!() <> "/results/home_manager_#{version}/share/doc/home-manager/options.json")
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn {k, v} ->
      Map.put(v, "name", k)
      |> normalize_home_manager()
    end)
    |> List.flatten()
    |> Meilisearch.upsert_packages(index_name)
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

  @is_nix_code ["example", "default"]

  defp normalize_option(option) do
    option
    |> Utils.normalize_map()
    |> Enum.map(fn
      {key, %{"_type" => "literalExpression", "text" => _text}} = option
      when key in @is_nix_code ->
        # Maybe format with nixpkgs-fmt ?
        option

      {key, text} when key in @is_nix_code ->
        {key,
         %{
           "_type" => nil,
           "text" => Jason.encode!(text) |> Jason.Formatter.pretty_print()
         }}

      {"description", %{"_type" => _type, "text" => text}} ->
        {"description", text}

      option ->
        option
    end)
    |> Map.new()
  end
end
