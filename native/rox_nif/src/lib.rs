#[macro_use]
extern crate rustler;
#[macro_use]
extern crate rustler_codegen;
#[macro_use]
extern crate lazy_static;
extern crate rocksdb;

use std::path::Path;
use std::ops::Deref;

use rustler::resource::ResourceArc;

use rustler::{
    NifEnv, NifTerm, NifEncoder, NifResult
};

use rocksdb::{
    DB,IteratorMode, Direction
};

mod atoms {
    rustler_atoms! {
        atom ok;
        atom error;
        // atom nil;
        // atom not_found;

        // Block Based Table Option atoms
        // atom no_block_cache;
        // atom block_size;
        // atom block_cache_size;
        // atom bloom_filter_policy;
        // atom format_version;
        // atom skip_table_builder_flush;
        // atom cache_index_and_filter_blocks;

        // CF Options Related atoms
        // atom block_cache_size_mb_for_point_lookup;
        // atom memtable_memory_budget;
        // atom write_buffer_size;
        // atom max_write_buffer_number;
        // atom min_write_buffer_number_to_merge;
        // atom compression;
        // atom num_levels;
        // atom level0_file_num_compaction_trigger;
        // atom level0_slowdown_writes_trigger;
        // atom level0_stop_writes_trigger;
        // atom max_mem_compaction_level;
        // atom target_file_size_base;
        // atom target_file_size_multiplier;
        // atom max_bytes_for_level_base;
        // atom max_bytes_for_level_multiplier;
        // atom expand_compaction_factor;
        // atom source_compaction_factor;
        // atom max_grandparent_overlap_factor;
        // atom soft_rate_limit;
        // atom hard_rate_limit;
        // atom arena_block_size;
        // atom disable_auto_compaction;
        // atom purge_redundant_kvs_while_flush;
        // atom compaction_style;
        // atom verify_checksums_in_compaction;
        // atom filter_deletes;
        // atom max_sequential_kip_in_iterations;
        // atom inplace_update_support;
        // atom inplace_update_num_locks;
        // atom table_factory_block_cache_size;
        // atom in_memory_mode;
        // atom block_based_table_options;

        // DB Options
        // atom total_threads;
        // atom create_if_missing;
        // atom create_missing_column_families;
        // atom error_if_exists;
        // atom paranoid_checks;
        // atom max_open_files;
        // atom max_total_wal_size;
        // atom disable_data_sync;
        // atom use_fsync;
        // atom db_paths;
        // atom db_log_dir;
        // atom wal_dir;
        // atom delete_obsolete_files_period_micros;
        // atom max_background_compactions;
        // atom max_background_flushes;
        // atom max_log_file_size;
        // atom log_file_time_to_roll;
        // atom keep_log_file_num;
        // atom max_manifest_file_size;
        // atom table_cache_numshardbits;
        // atom wal_ttl_seconds;
        // atom wal_size_limit_mb;
        // atom manifest_preallocation_size;
        // atom allow_os_buffer;
        // atom allow_mmap_reads;
        // atom allow_mmap_writes;
        // atom is_fd_close_on_exec;
        // atom skip_log_error_on_recovery;
        // atom stats_dump_period_sec;
        // atom advise_random_on_open;
        // atom access_hint;
        // atom compaction_readahead_size;
        // atom use_adaptive_mutex;
        // atom bytes_per_sync;
        // atom skip_stats_update_on_db_open;
        // atom wal_recovery_mode;

        // Read Options
        // atom verify_checksums;
        // atom fill_cache;
        // atom iterate_upper_bound;
        // atom tailing;
        // atom total_order_seek;
        // atom snapshot;
        // atom decode;

        // Write Options
        // atom sync;
        // atom disable_wal;
        // atom timeout_hint_us;
        // atom ignore_missing_column_families;
    }
}

struct DBHandle {
    pub db: DB,
}

macro_rules! handle_db_error {
    ($env:expr, $e:expr) => {
        match $e {
            Ok(inner) => inner,
            Err(err) => return Ok((atoms::error(), err.to_string().encode($env)).encode($env))
        }
    }
}

fn open<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let path: &Path =
        Path::new(args[0].decode()?);

    let db =
        handle_db_error!(env, DB::open_default(path));
    
    let resp =
        (atoms::ok(), ResourceArc::new(DBHandle{
            db: db,
        })).encode(env);

    Ok(resp)
}

fn count<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let db_arc: ResourceArc<DBHandle> = args[0].decode()?;
    let db_handle = db_arc.deref();

    let iterator = db_handle.db.iterator(IteratorMode::Start);

    let count = iterator.count();

    
    Ok((count as u32).encode(env))
}

rustler_export_nifs!(
    "Elixir.Rox.Native",
    [("open", 3, open),
    ("count", 1, count)],
    Some(on_load)
);

fn on_load<'a>(env: NifEnv<'a>, _load_info: NifTerm<'a>) -> bool {
    resource_struct_init!(DBHandle, env);

    true
}
