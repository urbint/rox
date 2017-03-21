defmodule RoxTest do
  use ExUnit.Case, async: false
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

    test "stream", %{db: db} do
      assert :ok = Rox.put(db, "stream_test", "val")

      count =
        Rox.stream(db)
        |> Enum.count

      assert count > 0
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
end
