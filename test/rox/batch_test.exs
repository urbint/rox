defmodule Rox.BatchTest do
  use ExUnit.Case, async: true

  alias Rox.Batch

  describe "merge/1" do
    test "stores operations in reverse order" do
      batches = [
        %Batch{operations: [put: {"key_a", "value_a"}]},
        %Batch{operations: [put: {"key_b", "value_b"}]},
        %Batch{operations: [delete: "key_a"]},
      ]

      assert Batch.merge(batches) == %Batch{
        operations: [
          delete: "key_a",
          put: {"key_b", "value_b"},
          put: {"key_a", "value_a"},
        ]
      }
    end

    test "works when a single batch contains multiple operations" do
      batches = [
        %Batch{operations: [put: {"key_b", "value_b"}, put: {"key_a", "value_a"}]},
        %Batch{operations: [delete: "key_a"]},
      ]

      assert Batch.merge(batches) == %Batch{
        operations: [
          delete: "key_a",
          put: {"key_b", "value_b"},
          put: {"key_a", "value_a"},
        ]
      }
    end
  end

end
