# Rox

Elixir wrapper around
[leo-project/erocksdb](https://github.com/leo-project/erocksdb)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `rox` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:rox, "~> 0.1.0"}]
    end
    ```

## Features

  * String friendly wrapping around erlang char lists
  * Auto encoding of non-binary types (tuples, maps, lists, etc) via
      `:erlang.term_to_binary/1`. (Use `decode: true` on `get`)
