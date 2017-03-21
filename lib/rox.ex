defmodule Rox do
  @moduledoc """
  Elixir wrapper for RocksDB.

  """

  alias __MODULE__.{DB,ColumnFamily,Native,Utils,Cursor}

  @opts_to_convert_to_bitlists [:db_log_dir, :wal_dir]

  @type compaction_style :: :level | :universal | :fifo | :none
  @type compression_type :: :snappy | :zlib | :bzip2 | :lz4 | :lz4h | :none

  @type key :: String.t | binary
  @type value :: any

  @type iterator_mode :: :start | :end | {:from, key, :forward | :backward}

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
    {:fill_cache, boolean} |
    {:iterate_upper_bound, binary}
    # {:snapshot, snapshot_handle} |
  ]

  @type write_options :: [
    {:sync, boolean} |
    {:disable_wal, boolean}
  ]

  @doc """
  Open a RocksDB with the specified database options and optional `column_families`.

  The database will automatically be closed when the BEAM VM releases it for garbage collection.

  """
  @spec open(file_path, db_options) :: {:ok, DB.t} | {:error, any}
  def open(path, db_opts \\ [], column_families \\ []) when is_binary(path) and is_list(db_opts) and is_list(column_families) do
    with {:ok, result} <- Native.open(path, to_map(db_opts), column_families) do
      {:ok, DB.wrap_resource(result)}
    end
  end

  @doc """
  Create a column family in `db` with `name` and `opts`.

  """
  @spec create_cf(DB.t, String.t, db_options) :: {:ok, ColumnFamily.t} | {:error, any}
  def create_cf(%DB{resource: raw_db} = db, name, opts \\ []) do
    with {:ok, result} <- Native.create_cf(raw_db, name, to_map(opts)) do
      {:ok, ColumnFamily.wrap_resource(db, result, name)}
    end
  end


  @doc """
  Put a key/value pair into the specified database or column family.
  
  Optionally takes a list of `write_options`.

  Non-binary values will automatically be encoded using the `:erlang.term_to_binary/1` function.

  """
  @spec put(DB.t | ColumnFamily.t, key, value, write_options) :: :ok | {:error, any}
  def put(db_or_cf, key, value, write_opts \\[])
  def put(%DB{resource: db}, key, value, write_opts) when is_binary(key) and is_list(write_opts), do:
    Native.put(db, key, Utils.encode(value), to_map(write_opts))
  def put(%ColumnFamily{db_resource: db, cf_resource: cf}, key, value, write_opts) when is_binary(key), do:
    Native.put_cf(db, cf, key, Utils.encode(value), to_map(write_opts))


  @doc """
  Get a key/value pair in the databse or column family with the specified `key`.

  Optionally takes a list of `read_options`.

  For non-binary terms that were stored, they will be automatically decoded.

  """
  @spec get(DB.t | ColumnFamily.t, key, read_options) :: {:ok, binary} | {:ok, value} | :not_found | {:error, any}
  def get(db_or_cf, key, opts \\ [])
  def get(%DB{resource: db}, key, opts) when is_binary(key) and is_list(opts) do
    Native.get(db, key, to_map(opts))
    |> Utils.decode
  end
  def get(%ColumnFamily{db_resource: db, cf_resource: cf}, key, opts) when is_binary(key) and is_list(opts) do
    Native.get_cf(db, cf, key, to_map(opts))
    |> Utils.decode
  end

  @doc """
  Returns a `Cursor.t` which will iterate records from the provided database or
  column family.

  Optionally takes an `iterator_mode`. Defaults to `:start`.
  
  The default arguments of this function is used for the `Enumerable` implementation
  for `DB` and `ColumnFamily` structs.
  
  """
  @spec stream(DB.t | ColumnFamily.t, iterator_mode) :: Cursor.t
  def stream(db_or_cf, mode \\ :start)
  def stream(%DB{resource: db}, mode) do
    with {:ok, resource} = Native.iterate(db, mode) do
      {:ok, Cursor.wrap_resource(resource)}
    end
  end
  def stream(%ColumnFamily{db_resource: db, cf_resource: cf}, mode) do
    with {:ok, resource} = Native.iterate_cf(db, cf, mode) do
      {:ok, Cursor.wrap_resource(resource)}
    end
  end


  @doc """
  Return the approximate number of keys in the database or specified column family.

  Implemented by calling GetIntProperty with `rocksdb.estimate-num-keys`

  """
  @spec count(DB.t | ColumnFamily.t) :: non_neg_integer | {:error, any}
  def count(%DB{resource: db}) do
    Native.count(db)
  end
  def count(%ColumnFamily{db_resource: db, cf_resource: cf}) do
    Native.count_cf(db, cf)
  end

  defp to_map(map) when is_map(map), do: map
  defp to_map([]), do: %{}
  defp to_map(enum), do: Enum.into(enum, %{})
end
