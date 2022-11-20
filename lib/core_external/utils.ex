defmodule CoreExternal.Utils do
  @moduledoc """
    Utilitary functions shared by `CoreExternal`
  """

  def normalize_map(%{} = map) do
    map
    |> Map.new(fn
      {k, %{} = v} ->
        {Macro.underscore(k), normalize_map(v)}

      {k, [_ | _] = v} ->
        {Macro.underscore(k), Enum.map(v, &normalize_map/1) |> List.flatten()}

      {k, v} ->
        {Macro.underscore(k), v}
    end)
  end

  def normalize_map(map), do: map
end
