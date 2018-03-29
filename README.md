# Rox

Rustler (Rust) powered erlang NIFs for RocksDB

## Installation

1. Add `rox` to your list of dependencies in `mix.exs`.

```ex
def deps do
  [
    {:rox, "~> 2.0"},
  ]
end
```

2. If using Elixir < 1.4, ensure rox is started before your application:
```ex
def application do
  [applications: [:rox]]
end
```


### Dependencies

Rox requires that Rust be available at compile time.

## Features

  * Support for column families.
  * Auto encoding of non-binary types (tuples, maps, lists, etc) via
      `:erlang.term_to_binary/1`.
  * Good Elixir citizen with `Enumerable` and `Collectable` being implemented for both
    `ColumnFamily.t` and `DB.t` structs.

## License

Copyright 2016 Urbint

Licensed under the MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
