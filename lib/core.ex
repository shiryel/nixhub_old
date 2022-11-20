defmodule Core do
  @moduledoc """
  Core keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defimpl Phoenix.HTML.Safe, for: Map do
    def to_iodata(map), do: Jason.encode_to_iodata!(map)
  end
end
