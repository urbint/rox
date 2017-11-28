defmodule RoxTest do
  use ExUnit.Case, async: false
  alias Rox.Batch
  doctest Rox

  setup_all do
    path =
      Path.join(__DIR__, "test.rocksdb")

    {:ok, db, %{"people" => people}} =
      Rox.open(path, [create_if_missing: true, auto_create_column_families: true], ["people"])

    on_exit fn ->
      File.rm_rf!(path)
      :ok
    end

    {:ok, %{db: db, people: people}}
  end

  describe "Working with default column family" do
    test "simple put and get", %{db: db} do
      assert :not_found = Rox.get(db, "put_test")

      assert :ok = Rox.put(db, "put_test", "val")

      assert {:ok, "val"} = Rox.get(db, "put_test")
    end

    test "put with a binary key", %{db: db} do
      binary_key =
        << 131, 251, 222, 111 >>

      assert :not_found = Rox.get(db, binary_key)
      assert :ok = Rox.put(db, binary_key, "test")
      assert {:ok, "test"} = Rox.get(db, binary_key)
    end

    test "stream", %{db: db} do
      for x <- 0..10 do
        :ok = Rox.put(db, "stream_test_#{x}", "val")
      end

      items =
        Rox.stream(db)
        |> Enum.into([])

      assert length(items) > 10
    end

    test "stream_keys", %{db: db} do
      Enum.each(0..9, & :ok = Rox.put(db, to_string(&1), &1))

      items =
        Rox.stream_keys(db, {:from, "0", :forward})
        |> Enum.take(10)

      assert ~w(0 1 2 3 4 5 6 7 8 9) == items
    end

    test "delete", %{db: db} do
      assert :not_found = Rox.get(db, "delete_test")
      assert :ok = Rox.put(db, "delete_test", "some_val")
      assert {:ok, _val} = Rox.get(db, "delete_test")
      assert :ok = Rox.delete(db, "delete_test")

      assert :not_found = Rox.get(db, "delete_test")
    end
  end

  describe "Working with prefixes in the default DB" do
    setup do
      id =
        :rand.uniform(1_000)
      path =
        Path.join(__DIR__, "test.rocksdb.prefixes.#{id}")

      {:ok, db} =
        Rox.open(path, fixed_prefix_length: 3, create_if_missing: true)

      on_exit fn ->
        File.rm_rf!(path)
        :ok
      end

      {:ok, %{db: db}}
    end

    test "stream_prefix", %{db: db} do
      a_items =
        Enum.map(0..9, &{"aaa#{&1}", &1})

      Enum.each(a_items, fn {k, v} -> :ok = Rox.put(db, k, v) end)
      Enum.each(0..9, & :ok = Rox.put(db, "bbb#{&1}", &1))

      result =
        Rox.stream_prefix(db, "aaa")
        |> Enum.take(10)

      assert a_items == result
    end

    test "count_prefix", %{db: db} do
      Enum.each(0..9, & :ok = Rox.put(db, "ccc#{&1}", &1))
      Enum.each(0..9, & :ok = Rox.put(db, "ddd#{&1}", &1))

      assert 10 == Rox.count_prefix(db, "ccc")
    end
  end

  describe "Working with prefixes in column families" do
    setup do
      id =
        :rand.uniform(1_000)
      path =
        Path.join(__DIR__, "test.rocksdb.prefixes.cfs.#{id}")

      {:ok, db, %{"people" => people}} =
        Rox.open(
          path,
          [fixed_prefix_length: 3, create_if_missing: true, auto_create_column_families: true],
          [{"people", fixed_prefix_length: 4}]
        )

      on_exit fn ->
        File.rm_rf!(path)
        :ok
      end

      {:ok, %{db: db, people: people}}
    end

    test "stream_prefix on the default db", %{db: db} do
      a_items =
        Enum.map(0..9, &{"aaa#{&1}", &1})

      Enum.each(a_items, fn {k, v} -> :ok = Rox.put(db, k, v) end)
      Enum.each(0..9, & :ok = Rox.put(db, "bbb#{&1}", &1))

      result =
        Rox.stream_prefix(db, "aaa")
        |> Enum.take(10)

      assert a_items == result
    end

    test "count_prefix on the default db", %{db: db} do
      Enum.each(0..9, & :ok = Rox.put(db, "ccc#{&1}", &1))
      Enum.each(0..9, & :ok = Rox.put(db, "ddd#{&1}", &1))

      assert 10 == Rox.count_prefix(db, "ccc")
    end

    test "stream_prefix on a column family", %{people: people} do
      a_items =
        Enum.map(0..9, &{"aaaa#{&1}", &1})

      Enum.each(a_items, fn {k, v} -> :ok = Rox.put(people, k, v) end)
      Enum.each(0..9, & :ok = Rox.put(people, "bbbb#{&1}", &1))

      result =
        Rox.stream_prefix(people, "aaaa")
        |> Enum.take(10)

      assert a_items == result
    end

    test "count_prefix on a column family", %{people: people} do
      Enum.each(0..9, & :ok = Rox.put(people, "cccc#{&1}", &1))
      Enum.each(0..9, & :ok = Rox.put(people, "dddd#{&1}", &1))

      assert 10 == Rox.count_prefix(people, "cccc")
    end
  end

  describe "Working with non-default column family" do
    test "simple put and get", %{people: people} do
      assert :not_found = Rox.get(people, "put_test")

      assert :ok = Rox.put(people, "put_test", "val")

      assert {:ok, "val"} = Rox.get(people, "put_test")
    end

    test "stream", %{people: people} do
      assert :ok = Rox.put(people, "stream_test", "val")

      count =
        Rox.stream(people)
        |> Enum.count

      assert count > 0
    end

    test "delete", %{people: people} do
      assert :not_found = Rox.get(people, "delete_test")
      assert :ok = Rox.put(people, "delete_test", "some_val")
      assert {:ok, _val} = Rox.get(people, "delete_test")
      assert :ok = Rox.delete(people, "delete_test")

      assert :not_found = Rox.get(people, "delete_test")
    end
  end

  describe "snapshots" do
    setup do
      id =
        :rand.uniform(1_000)
      path =
        Path.join(__DIR__, "test.rocksdb.prefixes.#{id}")

      {:ok, db, %{"people" => people}} =
        Rox.open(path,
                 [fixed_prefix_length: 2,
                  create_if_missing: true,
                  auto_create_column_families: true],
                 [{"people", fixed_prefix_length: 2}])

      on_exit fn ->
        File.rm_rf!(path)
        :ok
      end

      :ok = Rox.put(db, "snapshot_read_test", "some_val")
      Enum.each((1..9), & :ok = Rox.put(db, "zz#{&1}", &1))

      :ok = Rox.put(people, "goedel", "unsure")

      {:ok, snapshot} =
        Rox.create_snapshot(db)

      {:ok, %{db: db, snapshot: snapshot}}
    end

    test "snapshots can be read from", %{snapshot: snapshot} do
      assert {:ok, "some_val"} == Rox.get(snapshot, "snapshot_read_test")
    end

    test "snapshots allow streaming", %{snapshot: snapshot} do
      assert cursor =
        Rox.stream(snapshot, {:from, "zz", :forward})

      assert Enum.to_list(1..9) == cursor |> Enum.take(9) |> Enum.map(&elem(&1, 1))
    end

    test "snapshots don't see updates to the base db", %{snapshot: snapshot, db: db} do
      assert :not_found = Rox.get(snapshot, "snapshot_put_test")
      assert :ok = Rox.put(db, "snapshot_put_test", "some_val")
      assert {:ok, "some_val"} = Rox.get(db, "snapshot_put_test")
      assert :not_found = Rox.get(snapshot, "snapshot_put_test")
    end

    test "snapshots allow reading from column families", %{snapshot: snapshot} do
      {:ok, cf} =
        Rox.cf_handle(snapshot, "people")

      assert {:ok, "unsure"} = Rox.get(cf, "goedel")
    end

    test "snapshots don't see updates to column families", %{snapshot: snapshot, people: people} do
      {:ok, people_snap} =
        Rox.cf_handle(snapshot, people.name)

      assert :ok = Rox.put(people, "escher", "loopy")
      assert {:ok, "loopy"} = Rox.get(people, "escher")
      assert :not_found = Rox.get(people_snap, "escher")

      assert :ok = Rox.put(people, "goedel", "uncertain")
      assert {:ok, "unsure"} = Rox.get(people_snap, "goedel")
    end

    test "snapshots can read prefixes", %{snapshot: snapshot} do
      stream =
        Rox.stream_prefix(snapshot, "zz")

      assert Enum.to_list(1..9) == Enum.map(stream, &elem(&1, 1))
    end

    test "snapshots can read column family prefixes", %{snapshot: snapshot} do
      {:ok, cf} =
        Rox.cf_handle(snapshot, "people")

      stream =
        Rox.stream_prefix(cf, "go")

      assert [{"goedel", "unsure"}] == Enum.to_list(stream)
    end
  end

  describe "Batch Operations" do
    test "puts and deletes", %{db: db, people: people} do
      assert :not_found = Rox.get(db, "batch_put_test")
      assert :not_found = Rox.get(people, "batch_put_test")

      assert :ok =
        Batch.new
        |> Batch.put("batch_put_test", "works")
        |> Batch.put(people, "batch_put_test", "works")
        |> Batch.write(db)

      assert {:ok, "works"} = Rox.get(db, "batch_put_test")
      assert {:ok, "works"} = Rox.get(people, "batch_put_test")

      assert :ok =
        Batch.new
        |> Batch.delete("batch_put_test")
        |> Batch.delete(people, "batch_put_test")
        |> Batch.write(db)

      assert :not_found = Rox.get(db, "batch_put_test")
      assert :not_found = Rox.get(people, "batch_put_test")
    end
  end
end
