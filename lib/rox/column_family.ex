defmodule Rox.ColumnFamily do
  @moduledoc """
  Struct module representing a handle for a column family within a database.

  For working with the column family, see the functions in the top level
  `Rox` module.

  Implements the `Collectable` and `Enumerable` protocols.

  """

  alias Rox.{DB, Snapshot}

  @typedoc "A reference to a RocksDB column family"
  @type t :: %__MODULE__{
    db_resource: binary,
    cf_resource: binary,
    db_reference: reference,
    name: binary,
  }
  defstruct [:db_reference, :db_resource, :cf_resource, :name]

  @type name :: binary

  @doc false
  def wrap_resource(%DB{resource: db_resource, reference: db_reference}, resource, name) do
    %__MODULE__{
      db_resource: db_resource,
      db_reference: db_reference,
      cf_resource: resource,
      name: name
    }
  end

  def wrap_resource(%Snapshot{resource: db_resource, reference: db_reference}, resource, name) do
    %__MODULE__{
      db_resource: db_resource,
      db_reference: db_reference,
      cf_resource: resource,
      name: name
    }
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(handle, opts) do
      "#Rox.ColumnFamily<#{to_doc(handle.db_reference, opts)}>.#{handle.name}"
    end
  end

  defimpl Enumerable do
    def count(cf), do: {:ok, Rox.count(cf)}

    def member?(cf, {key, val}) do
      with {:ok, stored_val} <- Rox.get(cf, key) do
        stored_val == {:ok, val}
      else
        _ -> {:ok, false}
      end
    end
    def member?(_, _), do: {:ok, false}

    def reduce(cf, cmd, fun) do
      Rox.stream(cf)
      |> Enumerable.reduce(cmd, fun)
    end
  end

  defimpl Collectable do
    def into(cf) do
      collector_fun = fn
        cf, {:cont, {key, val}} ->
          :ok = Rox.put(cf, key, val)
          cf
        cf, :done ->
          cf
        _, :halt ->
          :ok
      end

      {cf, collector_fun}
    end
  end
end
