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
      File.rm_rf(path)
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
    setup %{db: db, people: people} do
      :ok = Rox.put(db, "snapshot_read_test", "some_val")
      Enum.each((1..9), & :ok = Rox.put(db, "zz#{&1}", &1))

      :ok = Rox.put(people, "goedel", "unsure")

      {:ok, snapshot} =
        Rox.create_snapshot(db)

      {:ok, %{snapshot: snapshot}}
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
