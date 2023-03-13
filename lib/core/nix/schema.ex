defmodule Core.Nix.Schema do
  @moduledoc """
    Common modules and attributes shared between Nix schemas
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @type t :: %unquote(__CALLER__.module){}

      @derive Jason.Encoder
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end
end
