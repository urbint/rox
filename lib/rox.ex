defmodule Rox do
  @moduledoc """
  Elixir wrapper for RocksDB.

  """

  alias __MODULE__.{DBHandle,CFHandle,Native}

  @opts_to_convert_to_bitlists [:db_log_dir, :wal_dir]

  @type compaction_style :: :level | :universal | :fifo | :none
  @type compression_type :: :snappy | :zlib | :bzip2 | :lz4 | :lz4h | :none

  @type key :: String.t | binary
  @type value :: any

  @opaque snapshot_handle :: :erocksdb.snapshot_handle

  @type file_path :: String.t


  @type block_based_table_options :: [
    {:no_block_cache, boolean} |
    {:block_size, pos_integer} |
    {:block_cache_size, pos_integer} |
    {:bloom_filter_policy, bits_per_key :: pos_integer} |
    {:format_version, 0 | 1 | 2} |
    {:skip_table_builder_flush, boolean} |
    {:cache_index_and_filter_blocks, boolean}
  ]

  @type access_hint :: :normal | :sequential | :willneed | :none
  @type wal_recovery_mode ::
    :tolerate_corrupted_tail_records |
    :absolute_consistency |
    :point_in_time_recovery |
    :skip_any_corrupted_records

  @type db_options :: [
    {:total_threads, pos_integer} |
    {:optimize_level_type_compaction_memtable_memory_budget, integer} |
    {:create_if_missing, boolean} |
    {:max_open_files, pos_integer} |
    {:compression_type, compression_type} |
    {:use_fsync, boolean} |
    {:bytes_per_sync, pos_integer} |
    {:disable_data_sync, boolean} |
    {:allow_os_buffer, boolean} |
    {:table_cache_num_shard_bits, pos_integer} |
    {:min_write_buffer_number, pos_integer} |
    {:max_write_buffer_number, pos_integer} |
    {:write_buffer_size, pos_integer} |
    {:max_bytes_for_level_base, pos_integer} |
    {:max_bytes_for_level_multiplier, pos_integer} |
    {:max_manifest_file_size, pos_integer} |
    {:target_file_size_base, pos_integer} |
    {:min_write_buffer_number_to_merge, pos_integer} |
    {:level_zero_file_num_compaction_trigger, non_neg_integer} |
    {:level_zero_slowdown_writes_trigger, non_neg_integer} |
    {:level_zero_stop_writes_trigger, non_neg_integer} |
    {:compaction_style, compaction_style} |
    {:max_background_compactions, pos_integer} |
    {:max_background_flushes, pos_integer} |
    {:disable_auto_compactions, boolean} |
    {:report_bg_io_stats, boolean} |
    {:num_levels, pos_integer}
  ]

  @type read_options :: [
    {:verify_checksums, boolean} |
    {:fill_cache, boolean} |
    {:iterate_upper_bound, binary} |
    {:tailing, boolean} |
    {:total_order_seek, boolean} |
    {:snapshot, snapshot_handle} |
    {:decode, boolean}
  ]

  @type write_options :: [
    {:sync, boolean} |
    {:disable_wal, boolean}
  ]

  @type iterator_action :: :first | :last | :next | :prev | binary

  @doc """
  Open a RocksDB with the specified database options and optional `column_families`.

  The database will automatically be closed when the BEAM VM releases it for garbage collection.

  """
  @spec open(file_path, db_options) :: {:ok, DBHandle.t} | {:error, any}
  def open(path, db_opts \\ [], column_families \\ []) when is_binary(path) and is_list(db_opts) and is_list(column_families) do
    with {:ok, result} <- Native.open(path, to_map(db_opts), column_families) do
      {:ok, DBHandle.wrap_resource(result)}
    end
  end

  @doc """
  Create a column family in `db` with `name` and `opts`.

  """
  @spec create_cf(DBHandle.t, String.t, db_options) :: {:ok, CFHandle.t} | {:error, any}
  def create_cf(%DBHandle{resource: db}, name, opts \\ []) do
    with {:ok, result} <- Native.create_cf(db, name, to_map(opts)) do
      {:ok, CFHandle.wrap_resource(result)}
    end
  end


  @doc """
  Put a key/value pair into the default column family handle

  """
  @spec put(DBHandle.t, key, value, write_options) :: :ok | {:error, any}
  def put(%DBHandle{resource: db}, key, value) when is_binary(key), do:
    Native.put(db, key, encode(value), %{})

  @doc """
  Put a key/value pair into the default column family handle with the provided
  write options

  """
  @spec put(DBHandle.t, key, value, write_options) :: :ok | {:error, any}
  def put(%DBHandle{resource: db}, key, value, write_opts) when is_binary(key) and (is_list(write_opts) or is_map(write_opts)), do:
    Native.put(db, key, encode(value), to_map(write_opts))


  @doc """
  Put a key/value pair into the specified column family with optional `write_options`

  """
  @spec put(DBHandle.t, CFHandle.t, key, value, write_options) :: :ok | {:error, any}
  def put(%DBHandle{resource: db}, %CFHandle{resource: cf}, key, value, write_opts \\ []) when is_binary(key), do:
    Native.put_cf(db, cf, key, encode(value), to_map(write_opts))


  @doc """
  Retrieve a key/value pair in the default column family

  For non binary terms, you may use `decode: true` to automatically decode the binary back into the term.
  """
  @spec get(DBHandle.t, key, read_options) :: {:ok, binary} | {:ok, value} | :not_found | {:error, any}
  def get(db, key, read_opts \\ []) do
    {auto_decode, read_opts} = Keyword.pop(read_opts, :decode)
    with {:ok, val} <- :erocksdb.get(db, key, read_opts) do
      if auto_decode do
        {:ok, :erlang.binary_to_term(val)}
      else
        {:ok, val}
      end
    end
  end


  @doc """
  Creates an Elixir stream of the keys within the `DBHandle.t`.

  """
  @spec stream_keys(DBHandle.t, read_options) :: Enumerable.t
  def stream_keys(db, read_opts \\ []) do
    Stream.resource(fn ->
      {:ok, iter} =
        :erocksdb.iterator(db, read_opts, :keys_only)

      {iter, :first}
    end, fn {iter, dir} ->
      case :erocksdb.iterator_move(iter, dir) do
        {:ok, key} -> {[key], {iter, :next}}
        {:error, :invalid_iterator} -> {:halt, {iter, :done}}
      end
    end, fn {iter, _dir} ->
      :erocksdb.iterator_close(iter)
    end)
  end

  def stream(db, read_opts \\ []) do
    {auto_decode, read_opts} =
      Keyword.pop(read_opts, :decode)

    scan = fn {iter, dir} ->
      case :erocksdb.iterator_move(iter, dir) do
        {:ok, key, val} -> {[{key, val}], {iter, :next}}
        {:error, :invalid_iterator} -> {:halt, {iter, :done}}
      end
    end

    scan_or_decode = if auto_decode do
      fn arg ->
        with {[{key, val}], acc} <- scan.(arg) do
          val = :erlang.binary_to_term(val)
          {[{key, val}], acc}
        end
      end
    else
      scan
    end

    Stream.resource(fn ->
      {:ok, iter} =
        :erocksdb.iterator(db, read_opts)
      {iter, :first}
    end, scan_or_decode, fn {iter, _dir} ->
      :erocksdb.iterator_close(iter)
    end)
  end

  defp sanitize_opts(opts) do
    {raw, rest} =
      Keyword.split(opts, @opts_to_convert_to_bitlists)

    converted =
      Enum.map(raw, fn {k, val} -> {k, to_charlist(val)} end)

    Keyword.merge(rest, converted)
  end


  @doc """
  Return the approximate number of keys in the default column family.

  Implemented by calling GetIntProperty with `rocksdb.estimate-num-keys`

  """
  @spec count(DBHandle.t) :: non_neg_integer | {:error, any}
  def count(%DBHandle{resource: resource}) do
    Native.count(resource)
  end

  defp to_map(map) when is_map(map), do: map
  defp to_map(enum), do: Enum.into(enum, %{})

  defp encode(val) when is_binary(val), do: val
  defp encode(val), do: :erlang.term_to_binary(val)
end
