defmodule Rox do
  @moduledoc """
  Elixir wrapper for RocksDB.

  """

  alias __MODULE__.{DBHandle,Native}

  @opts_to_convert_to_bitlists [:db_log_dir, :wal_dir]

  @type compaction_style :: :level | :universal | :fifo | :none
  @type compression_type :: :snappy | :zlib | :bzip2 | :lz4 | :lz4h | :none

  @type key :: String.t | binary
  @type value :: any

  @opaque cf_handle :: :erocksdb.cf_handle
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

  @type cf_options :: [
    {:block_cache_size_mb_for_point_lookup, non_neg_integer} |
    {:memtable_memory_budget, pos_integer} |
    {:write_buffer_size,  pos_integer} |
    {:max_write_buffer_number,  pos_integer} |
    {:min_write_buffer_number_to_merge,  pos_integer} |
    {:compression,  compression_type} |
    {:num_levels,  pos_integer} |
    {:level0_file_num_compaction_trigger,  integer} |
    {:level0_slowdown_writes_trigger,  integer} |
    {:level0_stop_writes_trigger,  integer} |
    {:max_mem_compaction_level,  pos_integer} |
    {:target_file_size_base,  pos_integer} |
    {:target_file_size_multiplier,  pos_integer} |
    {:max_bytes_for_level_base,  pos_integer} |
    {:max_bytes_for_level_multiplier,  pos_integer} |
    {:expanded_compaction_factor,  pos_integer} |
    {:source_compaction_factor,  pos_integer} |
    {:max_grandparent_overlap_factor,  pos_integer} |
    {:soft_rate_limit,  float} |
    {:hard_rate_limit,  float} |
    {:arena_block_size,  integer} |
    {:disable_auto_compactions,  boolean} |
    {:purge_redundant_kvs_while_flush,  boolean} |
    {:compaction_style,  compaction_style} |
    {:verify_checksums_in_compaction,  boolean} |
    {:filter_deletes,  boolean} |
    {:max_sequential_skip_in_iterations,  pos_integer} |
    {:inplace_update_support,  boolean} |
    {:inplace_update_num_locks,  pos_integer} |
    {:table_factory_block_cache_size, pos_integer} |
    {:in_memory_mode, boolean} |
    {:block_based_table_options, block_based_table_options}
  ]

  @type db_path :: {:db_path, name :: String.t, options :: cf_options}
  @type cf_descriptor :: {:cf_descriptor, name :: String.t, options :: cf_options}
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
    {:level_zero_stop_writes_trigger, non_neg_integer}
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
    {:disable_wal, boolean} |
    {:timeout_hint_us, non_neg_integer} |
    {:ignore_missing_column_families, boolean}
  ]

  @type write_actions :: [
    {:put, key, value} |
    {:put, cf_handle, key, value} |
    {:delete, key} |
    {:delete, cf_handle, key} |
    :clear
  ]

  @type iterator_action :: :first | :last | :next | :prev | binary

  @doc """
  Open a RocksDB with the specified database options and column family options.

  The database will automatically be closed when the BEAM VM releases it for garbage collection.

  """
  @spec open(file_path, db_options, cf_options) :: {:ok, DBHandle.t} | {:error, any}
  def open(path, db_opts \\ [], cf_opts \\ []) do
    with {:ok, result} <- Native.open(path, to_map(db_opts), to_map(cf_opts)) do
      {:ok, DBHandle.wrap_resource(result)}
    end
  end


  @doc """
  Put a key/value pair into the default column family handle

  """
  @spec put(DBHandle.t, key, value) :: :ok | {:error, any}
  def put(db, key, value) when is_binary(value), do:
    :erocksdb.put(db, key, value, [])

  def put(db, key, value), do:
    :erocksdb.put(db, key, :erlang.term_to_binary(value), [])


  @doc """
  Put a key/value pair into the default column family handle with the provided
  write options

  """
  @spec put(DBHandle.t, key, value, write_options) :: :ok | {:error, any}
  def put(db, key, value, write_opts) when is_list(write_opts) and is_binary(value), do:
    :erocksdb.put(db, key, value, write_opts)

  def put(db, key, value, write_opts) when is_list(write_opts), do:
    :erocksdb.put(db, key, :erlang.term_to_binary(value), write_opts)


  @doc """
  Put a key/value pair into the specified column family with optional `write_options`

  """
  @spec put(DBHandle.t, cf_handle, key, value, write_options) :: :ok | {:error, any}
  def put(db, cf, key, value, write_opts \\ [])

  def put(db, cf, key, value, write_opts) when is_binary(value), do:
    :erocksdb.put(db, cf, key, value, write_opts)

  def put(db, cf, key, value, write_opts), do:
    :erocksdb.put(db, cf, key, :erlang.term_to_binary(value), write_opts)


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

  defp to_map(nil), do: nil
  defp to_map(enum), do: Enum.into(enum, %{})
end
