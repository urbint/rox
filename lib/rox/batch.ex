defmodule Rox.Batch do
  @moduledoc """
  Module for performing atomic write operations on a database.
  
  """

  alias Rox.{DB, ColumnFamily, Utils, Native}
  alias __MODULE__

  @typedoc "A reference to a batch operation"
  @type t :: %__MODULE__{operations: [op]}
  defstruct [operations: []]

  @typep op
    :: {:put, {key :: binary, value :: binary}}
     | {:put_cf, {ColumnFamily.t, key :: binary, value :: binary}}
     | {:delete, key :: binary}
     | {:delete_cf, {ColumnFamily.t, key :: binary, value :: binary}}

  @doc """
  Creates a new `Batch` operation

  """
  @spec new :: t
  def new do
    %Batch{}
  end

  @doc """
  Returns a new `Batch` with a put operation scheduled.

  """
  @spec put(t, Rox.key, Rox.value) :: t
  def put(%Batch{operations: ops} = batch, key, value) when is_binary(key) do
    %{batch | operations: [{:put, {key, Utils.encode(value)}} | ops]}
  end

  @doc """
  Returns a new `Batch` with a put operation scheduled for the `column_family`.
  
  """
  @spec put(t, ColumnFamily.t, Rox.key, Rox.value) :: t
  def put(%Batch{operations: ops} = batch, %ColumnFamily{cf_resource: cf}, key, value) when is_binary(key) do
    %{batch | operations: [{:put_cf, {cf, key, Utils.encode(value)}} | ops]}
  end


  @doc """
  Schedules a delete operation in the `batch`.
  
  """
  @spec delete(t, Rox.key) :: t
  def delete(%Batch{operations: ops} = batch, key) when is_binary(key) do
    %{batch | operations: [{:delete, key} | ops]}
  end

  @doc """
  Schedules a delete operation in the `batch` for `key` in `column_family`.
  
  """
  @spec delete(t, ColumnFamily.t, Rox.key) :: t
  def delete(%Batch{operations: ops} = batch, %ColumnFamily{cf_resource: cf}, key) when is_binary(key) do
    %{batch | operations: [{:delete_cf, {cf, key}} | ops]}
  end

  @doc """
  Atomically commits the operations in the `batch` to the `db`.
  
  """
  @spec write(t, DB.t) :: :ok | {:error, reason :: any}
  def write(%Batch{operations: ops}, %DB{resource: db}) do
    ops
    |> :lists.reverse
    |> Native.batch_write(db)
  end


  @doc """
  Merges a list of `Batch.t` into a single `Batch.t`.

  """
  @spec merge([t]) :: t
  def merge(batches) do
    batches
    |> Enum.reduce(Batch.new, fn %Batch{operations: ops}, %Batch{operations: merge_ops} = acc ->
      %{acc | operations: Enum.concat(ops, merge_ops)}
    end)
  end

end
