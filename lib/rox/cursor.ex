defmodule Rox.Cursor do
  @moduledoc """
  Struct module representing a cursor for the Rox database
  
  """

  @typedoc "A cursor for iterating over a database or column family"
  @type t :: %__MODULE__{
    resource: binary
  }
  defstruct [:resource]

  @doc false
  def wrap_resource(resource), do: %__MODULE__{resource: resource}

  defimpl Inspect do
    def inspect(handle, _) do
      "#Rox.Cursor<>"
    end
  end
end
