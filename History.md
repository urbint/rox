
1.2.2 / 2017-07-03
==================

  * chore(rustler): upgrade rustler to 0.10.1 to support OTP20

1.2.1 / 2017-06-29
==================

  * feat(): OTP 20 and Elixir 1.4.5 support

1.2.0 / 2017-06-27
==================

  * fix(): dialyzer specs on Rox.batch_write/2
  * feat(batch): Implement merge/2
  * feat(batch): Impls batch merging

1.1.0 / 2017-06-15
==================

  * feat(): add Batch commands (atomic operations)

1.0.2 / 2017-05-26
==================

  * fix(): no longer crash if DB reference is released before an iterator ref
  * deps(): update rust dependencies
  * test(stream): better testing
  * fix(): error when auto creating non existent column families

1.0.0 / 2017-03-21
==================

Major rewrite switching to Rustler based NIFs.

Changes include:

- Support for column families
- Implementation of `Enumerable` and `Collectable` for both `ColumnFamily.t` and
  `DB.t`
- Drop support for `stream_keys/1`. Use `stream/1` with a map instead.
- Support for streaming from arbitrary locations (see `stream/1` docs).
- Support for deletion
