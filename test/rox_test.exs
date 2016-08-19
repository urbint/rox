defmodule RoxTest do
  use ExUnit.Case, async: false
  doctest Rox

  setup do
    path = Path.join(__DIR__, "test.rocksdb")
    {:ok, db} = Rox.open(path, create_if_missing: true)

    on_exit fn ->
      Rox.close(db)
      File.rm_rf(path)
      :ok
    end

    {:ok, %{db: db}}
  end

  test "simple put and get", %{db: db} do
    assert :not_found = Rox.get(db, "key")
    :ok = Rox.put(db, "key", "val")

    assert {:ok, "val"} = Rox.get(db, "key")
  end

  test "stream_keys", %{db: db} do
    :ok = Rox.put(db, "key", "val")

    count = Rox.stream_keys(db)
    |> Enum.count

    assert count == 1
  end

  test "stream", %{db: db} do
    :ok = Rox.put(db, "key", "val")

    count = Rox.stream(db)
    |> Enum.count

    assert count == 1
  end

  test "partial exhaustion of a stream", %{db: db} do
    :ok = Rox.put(db, "key", "val")
    :ok = Rox.put(db, "alt-key", "val")

    Rox.stream_keys(db) |> Enum.take(1)
  end
end
