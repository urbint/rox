#[macro_use]
extern crate rustler;
#[macro_use]
extern crate rustler_codegen;
#[macro_use]
extern crate lazy_static;
extern crate rocksdb;
extern crate librocksdb_sys;

use std::path::Path;
use std::ops::Deref;
use std::sync::{Mutex};

use rustler::resource::ResourceArc;

use librocksdb_sys::rocksdb_column_family_handle_t;

use rustler::{
    NifEnv, NifTerm, NifEncoder, NifResult,NifDecoder,NifError
};

use rustler::types::list::NifListIterator;

use rocksdb::{
    DB, IteratorMode, Options, DBCompressionType, WriteOptions
};

mod atoms {
    rustler_atoms! {
        atom ok;
        atom error;
        // atom nil;
        // atom not_found;

        // Compression Type Atoms
        atom snappy;
        atom zlib;
        atom bzip2;
        atom lz4;
        atom lz4h;
        atom none;
            

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
        atom total_threads;
        atom optimize_level_type_compaction_memtable_memory_budget;
        atom create_if_missing;
        atom max_open_files;
        atom compression_type;
        atom use_fsync;
        atom bytes_per_sync;
        atom disable_data_sync;
        atom allow_os_buffer;
        atom table_cache_num_shard_bits;
        atom min_write_buffer_number;
        atom max_write_buffer_number;
        atom write_buffer_size;
        atom max_bytes_for_level_base;
        atom max_bytes_for_level_multiplier;
        atom max_manifest_file_size;
        atom target_file_size_base;
        atom min_write_buffer_number_to_merge;
        atom level_zero_file_num_compaction_trigger;
        atom level_zero_slowdown_writes_trigger;
        atom level_zero_stop_writes_trigger;
        atom compaction_style;
        atom max_background_compactions;
        atom max_background_flushes;
        atom disable_auto_compactions;
        atom report_bg_io_stats;
        atom num_levels;
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
        atom sync;
        atom disable_wal;
    }
}

struct DBHandle {
    pub db: Mutex<DB>,
}

struct CFHandle {
    pub cf: *mut rocksdb_column_family_handle_t,
}

unsafe impl Sync for CFHandle {}
unsafe impl Send for CFHandle {}

enum CompressionType {
    None,
    Snappy,
    Zlib,
    Bz2,
    Lz4,
    Lz4hc,
}

impl <'a> NifDecoder<'a> for CompressionType {
    fn decode(term: NifTerm<'a>) -> NifResult<Self> {
        if atoms::none() == term { Ok(CompressionType::None) }
        else if atoms::snappy()  == term { Ok(CompressionType::Snappy) }
        else if atoms::zlib()    == term { Ok(CompressionType::Zlib) }
        else if atoms::bzip2()   == term { Ok(CompressionType::Bz2) }
        else if atoms::lz4()     == term { Ok(CompressionType::Lz4) }
        else if atoms::lz4h()    == term { Ok(CompressionType::Lz4hc) }
        else { Err(NifError::BadArg) }
    }
}

impl Into<DBCompressionType> for CompressionType {
    fn into(self) -> DBCompressionType {
        match self {
            CompressionType::None => DBCompressionType::None,
            CompressionType::Snappy => DBCompressionType::Snappy,
            CompressionType::Zlib => DBCompressionType::Zlib,
            CompressionType::Bz2 => DBCompressionType::Bz2,
            CompressionType::Lz4 => DBCompressionType::Lz4,
            CompressionType::Lz4hc => DBCompressionType::Lz4hc,
        }
    }
}

macro_rules! handle_error {
    ($env:expr, $e:expr) => {
        match $e {
            Ok(inner) => inner,
            Err(err) => return Ok((atoms::error(), err.to_string().encode($env)).encode($env))
        }
    }
}

fn decode_write_options<'a>(env: NifEnv<'a>, arg: NifTerm<'a>) -> NifResult<WriteOptions> {
    let mut opts = WriteOptions::new();

    if let Ok(sync) = arg.map_get(atoms::sync().to_term(env)) {
        opts.set_sync(sync.decode()?);
    }

    if let Ok(disable_wal) = arg.map_get(atoms::disable_wal().to_term(env)) {
        opts.disable_wal(disable_wal.decode()?);
    }

    Ok(opts)
}

fn decode_db_options<'a>(env: NifEnv<'a>, arg: NifTerm<'a>) -> NifResult<Options> {
    let mut opts = Options::default();

    if let Ok(count) = arg.map_get(atoms::total_threads().to_term(env)) {
        opts.increase_parallelism(count.decode()?);
    }

    if let Ok(memtable_budget) = arg.map_get(atoms::optimize_level_type_compaction_memtable_memory_budget().to_term(env)) {
        let i_size: u64 = memtable_budget.decode()?;
        opts.optimize_level_style_compaction(i_size as usize);
    }

    if let Ok(create_if_missing) = arg.map_get(atoms::create_if_missing().to_term(env)) {
        opts.create_if_missing(create_if_missing.decode()?);
    }

    if let Ok(compression_type_opt) = arg.map_get(atoms::compression_type().to_term(env)) {
        let compression_type: CompressionType = compression_type_opt.decode()?;
        opts.set_compression_type(compression_type.into());
    }

    // TODO: Set Compression Type Per Level

    if let Ok(max_open_files) = arg.map_get(atoms::max_open_files().to_term(env)) {
        opts.set_max_open_files(max_open_files.decode()?);
    }

    if let Ok(use_fsync) = arg.map_get(atoms::use_fsync().to_term(env)) {
        opts.set_use_fsync(use_fsync.decode()?);
    }

    if let Ok(bytes_per_sync) = arg.map_get(atoms::bytes_per_sync().to_term(env)) {
        opts.set_bytes_per_sync(bytes_per_sync.decode()?);
    }

    if let Ok(disable_sync) = arg.map_get(atoms::disable_data_sync().to_term(env)) {
        opts.set_disable_data_sync(disable_sync.decode()?);
    }

    if let Ok(allow_os_buffer) = arg.map_get(atoms::allow_os_buffer().to_term(env)) {
        opts.set_allow_os_buffer(allow_os_buffer.decode()?);
    }

    if let Ok(nbits) = arg.map_get(atoms::table_cache_num_shard_bits().to_term(env)) {
        opts.set_table_cache_num_shard_bits(nbits.decode()?);
    }

    if let Ok(nbuf) = arg.map_get(atoms::min_write_buffer_number().to_term(env)) {
        opts.set_min_write_buffer_number(nbuf.decode()?);
    }

    if let Ok(nbuf) = arg.map_get(atoms::max_write_buffer_number().to_term(env)) {
        opts.set_max_write_buffer_number(nbuf.decode()?);
    }

    if let Ok(size) = arg.map_get(atoms::write_buffer_size().to_term(env)) {
        let i_size: u64 = size.decode()?;
        opts.set_write_buffer_size(i_size as usize);
    }

    if let Ok(max_bytes) = arg.map_get(atoms::max_bytes_for_level_base().to_term(env)) {
        opts.set_max_bytes_for_level_base(max_bytes.decode()?);
    }

    if let Ok(multiplier) = arg.map_get(atoms::max_bytes_for_level_multiplier().to_term(env)) {
        opts.set_max_bytes_for_level_multiplier(multiplier.decode()?);
    }

    if let Ok(max_size) = arg.map_get(atoms::max_manifest_file_size().to_term(env)) {
        let i_size: u64 = max_size.decode()?;
        opts.set_max_manifest_file_size(i_size as usize);
    }

    if let Ok(target_size) = arg.map_get(atoms::target_file_size_base().to_term(env)) {
        opts.set_target_file_size_base(target_size.decode()?);
    }

    if let Ok(to_merge) = arg.map_get(atoms::min_write_buffer_number_to_merge().to_term(env)) {
        opts.set_min_write_buffer_number_to_merge(to_merge.decode()?);
    }

    if let Ok(n) = arg.map_get(atoms::level_zero_file_num_compaction_trigger().to_term(env)) {
        opts.set_level_zero_file_num_compaction_trigger(n.decode()?);
    }

    if let Ok(n) = arg.map_get(atoms::level_zero_slowdown_writes_trigger().to_term(env)) {
        opts.set_level_zero_slowdown_writes_trigger(n.decode()?);
    }

    if let Ok(n) = arg.map_get(atoms::level_zero_stop_writes_trigger().to_term(env)) {
        opts.set_level_zero_stop_writes_trigger(n.decode()?);
    }

    // Todo set compaction style

    if let Ok(n) = arg.map_get(atoms::max_background_compactions().to_term(env)) {
        opts.set_max_background_compactions(n.decode()?);
    }

    if let Ok(n) = arg.map_get(atoms::max_background_flushes().to_term(env)) {
        opts.set_max_background_flushes(n.decode()?);
    }

    if let Ok(disable) = arg.map_get(atoms::disable_auto_compactions().to_term(env)) {
        opts.set_disable_auto_compactions(disable.decode()?);
    }

    if let Ok(bg_io_stats) = arg.map_get(atoms::report_bg_io_stats().to_term(env)) {
        opts.set_report_bg_io_stats(bg_io_stats.decode()?);
    }

    // Todo: set WAL Recovery Mode

    if let Ok(num_levels) = arg.map_get(atoms::num_levels().to_term(env)) {
        opts.set_num_levels(num_levels.decode()?);
    }


    Ok(opts)
}

fn open<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let path: &Path =
        Path::new(args[0].decode()?);

    let db_opts =
        if args[1].map_size()? > 0 {
            decode_db_options(env, args[1])?
        } else {
            Options::default()
        };

    let cf: Vec<&str> =
        if args[2].list_length()? == 0 {
            vec![]
        } else {
            let iter: NifListIterator = try!(args[2].decode());
            let result: Vec<&str> =
                try!(iter
                .map(|x| x.decode::<&str>())
                .collect::<NifResult<Vec<&str>>>());

            result
        };

    let db: DB = handle_error!(env, DB::open_cf(&db_opts, path, &cf));
    
    let resp =
        (atoms::ok(), ResourceArc::new(DBHandle{
            db: Mutex::new(db),
        })).encode(env);

    Ok(resp)
}

fn count<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let db_arc: ResourceArc<DBHandle> = args[0].decode()?;
    let db_handle = db_arc.deref();

    let iterator = db_handle.db.lock().unwrap().iterator(IteratorMode::Start);

    let count = iterator.count();

    
    Ok((count as u64).encode(env))
}

fn create_cf<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let db_arc: ResourceArc<DBHandle> = args[0].decode()?;
    let mut db = db_arc.deref().db.lock().unwrap();

    let name: &str = args[1].decode()?;
    let has_db_opts = args[2].map_size()? > 0;
    let opts =
        if has_db_opts { decode_db_options(env, args[2])? } else { Options::default() };


    let cf = handle_error!(env, db.create_cf(name, &opts));

    let resp =
        (atoms::ok(), ResourceArc::new(CFHandle{cf: cf})).encode(env);

    Ok(resp)
}

fn put<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let db_arc: ResourceArc<DBHandle> = args[0].decode()?;
    let db = db_arc.deref().db.lock().unwrap();

    let key: &str = args[1].decode()?;
    let val: &str = args[2].decode()?;

    let resp =
        if args[3].map_size()? > 0 {
            let write_opts = decode_write_options(env, args[2])?;
            db.put_opt(key.as_bytes(), val.as_bytes(), &write_opts)
        } else {
            db.put(key.as_bytes(), val.as_bytes())
        };


    handle_error!(env, resp);


    Ok(atoms::ok().encode(env))
}

fn put_cf<'a>(env: NifEnv<'a>, args: &[NifTerm<'a>]) -> NifResult<NifTerm<'a>> {
    let db_arc: ResourceArc<DBHandle> = args[0].decode()?;
    let db = db_arc.deref().db.lock().unwrap();

    let cf_arc: ResourceArc<CFHandle> = args[1].decode()?;
    let cf = cf_arc.deref().cf;

    let key: &str = args[2].decode()?;
    let val: &str = args[3].decode()?;

    let resp =
        if args[4].map_size()? > 0 {
            let write_opts = decode_write_options(env, args[2])?;
            db.put_cf_opt(cf, key.as_bytes(), val.as_bytes(), &write_opts)
        } else {
            db.put_cf(cf, key.as_bytes(), val.as_bytes())
        };


    handle_error!(env, resp);


    Ok(atoms::ok().encode(env))
}

rustler_export_nifs!(
    "Elixir.Rox.Native",
    [("open", 3, open),
    ("create_cf", 3, create_cf),
    ("put", 4, put),
    ("put_cf", 5, put_cf),
    ("count", 1, count)],
    Some(on_load)
);

fn on_load<'a>(env: NifEnv<'a>, _load_info: NifTerm<'a>) -> bool {
    resource_struct_init!(DBHandle, env);
    resource_struct_init!(CFHandle, env);

    true
}
