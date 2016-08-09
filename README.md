# Rox

Elixir wrapper around
[leo-project/erocksdb](https://github.com/leo-project/erocksdb) providing
RocksDB as NIFs to Elixir

## Installation

Slow down there cow-boy. This library is still a WIP.

## Features

  * String friendly wrapping around erlang char lists
  * Auto encoding of non-binary types (tuples, maps, lists, etc) via
      `:erlang.term_to_binary/1`. (Use `decode: true` on `get`)
