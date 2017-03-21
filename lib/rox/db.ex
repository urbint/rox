defmodule Rox.DB do
  @moduledoc """
  Struct module representing a handle for a database.
  
  For working with the database, see the functions in the top
  level `Rox` module.
  
  Implements the `Collectable` and `Enumerable` protocol.

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
end
