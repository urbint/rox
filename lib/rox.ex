defmodule Rox do
  @opts_to_convert_to_bitlists [:db_log_dir, :wal_dir]

  @type compaction_style :: :level | :universal | :fifo | :none
  @type compression_type :: :snappy | :zlib | :bzip2 | :lz4 | :lz4h | :none

  @type db_handle :: binary
  @type cf_handle :: binary
  @type itr_handle :: binary
  @type snapshot_handle :: binary

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
    {:create_if_missing, boolean} |
    {:create_missing_column_families, boolean} |
    {:error_if_exists, boolean} |
    {:paranoid_checks, boolean} |
    {:max_open_files, integer} |
    {:max_total_wal_size, non_neg_integer} |
    {:disable_data_sync, boolean} |
    {:use_fsync, boolean} |
    {:db_paths, [db_path]} |
    {:db_log_dir, file_path} |
    {:wal_dir, file_path} |
    {:delete_obsolete_files_period_micros, pos_integer} |
    {:max_background_compactions, pos_integer} |
    {:max_background_flushes, pos_integer} |
    {:max_log_file_size, non_neg_integer} |
    {:log_file_time_to_roll, non_neg_integer} |
    {:keep_log_file_num, pos_integer} |
    {:max_manifest_file_size, pos_integer} |
    {:table_cache_numshardbits, pos_integer} |
    {:wal_ttl_seconds, non_neg_integer} |
    {:wal_size_limit_mb, non_neg_integer} |
    {:manifest_preallocation_size, pos_integer} |
    {:allow_os_buffer, boolean} |
    {:allow_mmap_reads, boolean} |
    {:allow_mmap_writes, boolean} |
    {:is_fd_close_on_exec, boolean} |
    {:skip_log_error_on_recovery, boolean} |
    {:stats_dump_period_sec, non_neg_integer} |
    {:advise_random_on_open, boolean} |
    {:access_hint, access_hint} |
    {:compaction_readahead_size, non_neg_integer} |
    {:use_adaptive_mutex, boolean} |
    {:bytes_per_sync, non_neg_integer} |
    {:skip_stats_update_on_db_open, boolean} |
    {:wal_recovery_mode, wal_recovery_mode}
  ]

  @type read_options :: [
    {:verify_checksums, boolean} |
    {:fill_cache, boolean} |
    {:iterate_upper_bound, binary} |
    {:tailing, boolean} |
    {:total_order_seek, boolean} |
    {:snapshot, snapshot_handle}
  ]

  @type write_options :: [
    {:sync, boolean} |
    {:disable_wal, boolean} |
    {:timeout_hint_us, non_neg_integer} |
    {:ignore_missing_column_families, boolean}
  ]

  @type write_actions :: [
    {:put, key :: binary, value :: binary} |
    {:put, cf_handle, key :: binary, value :: binary} |
    {:delete, key :: binary} |
    {:delete, cf_handle, key :: binary} |
    :clear
  ]

  @type iterator_action :: :first | :last | :next | :prev | binary

  @doc """
  Open a RocksDB with the specified read options
  """

  @spec open(path :: file_path, db_opts :: db_options, cf_opts :: cf_options) :: {:ok, db_handle} | {:error, any}
  def open(path, db_opts \\ [], cf_opts \\ []) do
    :erocksdb.open(to_charlist(path), sanitize_opts(db_opts), sanitize_opts(cf_opts))
  end

  defp sanitize_opts(opts) do
    [ raw, rest ] = Keyword.split(opts, @opts_to_convert_to_bitlists)
    converted = Enum.map(raw, fn {k, val} -> {k, to_charlist(val)} end)
    Keyword.merge(rest, converted)
  end
end
