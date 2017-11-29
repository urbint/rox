defmodule Rox.DB do
  @moduledoc """
  Struct module representing a handle for a database.

  For working with the database, see the functions in the top
  level `Rox` module.

  Implements the `Collectable` and `Enumerable` protocols.

  """

  @typedoc "A reference to an open RocksDB database"
  @type t :: %__MODULE__{resource: binary, reference: reference}
  defstruct [:resource, :reference]


  @doc false
  def wrap_resource(resource) do
    %__MODULE__{resource: resource, reference: make_ref()}
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(handle, opts) do
      "#Rox.DB<#{to_doc(handle.reference, opts)}>"
    end
  end

  defimpl Enumerable do
    def count(db), do: {:ok, Rox.count(db)}

    def member?(db, {key, val}) do
      with {:ok, stored_val} <- Rox.get(db, key) do
        stored_val == {:ok, val}
      else
        _ -> {:ok, false}
      end
    end
    def member?(_, _), do: {:ok, false}

    def reduce(db, cmd, fun) do
      Rox.stream(db)
      |> Enumerable.reduce(cmd, fun)
    end
  end

  defimpl Collectable do
    def into(db) do
      collector_fun = fn
        db, {:cont, {key, val}} when is_binary(key) ->
          :ok = Rox.put(db, key, val)
          db
        db, :done ->
          db
        _, :halt ->
          :ok
      end

      {db, collector_fun}
    end
  end
end
