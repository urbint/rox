defmodule Rox.ColumnFamily do
  @moduledoc """
  Struct module representing a handle for a column family within a database.
  
  For working with the column family, see the functions in the top level
  `Rox` module.
  
  Implements the `Collectable` and `Enumerable` protocols.

  """

  alias Rox.DB

  @typedoc "A reference to a RocksDB column family"
  @type t :: %__MODULE__{
    db_resource: binary, cf_resource: binary,
    db_reference: reference, name: binary,
  }
  defstruct [:db_reference, :db_resource, :cf_resource, :name]


  @doc false
  def wrap_resource(%DB{resource: db_resource, reference: db_reference}, resource, name) do
    %__MODULE__{
      db_resource: db_resource, db_reference: db_reference,
      cf_resource: resource, name: name
    }
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(handle, opts) do
      "#Rox.ColumnFamily<#{to_doc(handle.db_reference, opts)}>.#{handle.name}"
    end
  end
end
