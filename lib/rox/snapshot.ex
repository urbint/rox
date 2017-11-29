defmodule Rox.Snapshot do
  @moduledoc """
  Struct module representing a handle for a database snapshot.

  Snapshots support all read operations that a `Rox.DB` supports, and implement `Enumerable`, but
  not `Collectable`

  """

  alias Rox.DB



  @typedoc "A reference to a RocksDB database snapshot"
  @type t :: %__MODULE__{
    resource: binary,
    reference: reference,
    db: DB.t
  }

  @enforce_keys [:resource, :reference, :db]
  defstruct [
    :resource,
    :reference,
    :db
  ]

  @doc false
  def wrap_resource(%DB{} = db, resource) do
    %__MODULE__{resource: resource, reference: make_ref(), db: db}
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(handle, opts) do
      "#Rox.Snapshot<#{to_doc(handle.reference, opts)}>"
    end
  end

  defimpl Enumerable do
    def count(snapshot), do: {:ok, Rox.count(snapshot)}

    def member?(snapshot, {key, val}) do
      with {:ok, stored_val} <- Rox.get(snapshot, key) do
        stored_val == {:ok, val}
      else
        _ -> {:ok, false}
      end
    end
    def member?(_, _), do: {:ok, false}

    def reduce(snapshot, cmd, fun) do
      Rox.stream(snapshot)
      |> Enumerable.reduce(cmd, fun)
    end
  end
end
