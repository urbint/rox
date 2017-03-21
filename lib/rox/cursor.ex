defmodule Rox.Cursor do
  @moduledoc """
  Struct module representing a cursor for the Rox database
  
  """

  @typedoc "A cursor for iterating over a database or column family"
  @type t :: %__MODULE__{
    resource: binary, mode: mode
  }

  defstruct [:resource, :mode]

  @type mode :: :start | :end | {:from, Rox.key, :forward | :backward}

  @doc false
  def wrap_resource(resource, mode) do
    %__MODULE__{resource: resource, mode: mode}
  end


  defimpl Inspect do
    def inspect(_, _) do
      "#Rox.Cursor<>"
    end
  end


  defimpl Enumerable do
    alias Rox.{Cursor,Native,Utils}

    def count(_), do: {:error, __MODULE__}
    def member?(_, _), do: {:error, __MODULE__}

    def reduce(%Cursor{resource: raw, mode: mode}, {:halt, acc}, _fun) do
      Native.iterator_reset(raw, mode)
      {:halted, acc}
    end
    def reduce(%Cursor{} = cursor, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(cursor, &1, fun)}
    end
    def reduce(%Cursor{resource: raw, mode: mode} = cursor, {:cont, acc}, fun) do
      case Native.iterator_next(raw) do
        :done ->
          Native.iterator_reset(raw, mode)
          {:done, acc}

        {key, value} ->
          value =
            Utils.decode(value)

          reduce(cursor, fun.({key, value}, acc), fun)
      end
    end
  end
end
