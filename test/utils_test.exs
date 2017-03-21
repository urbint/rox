defmodule Rox.UtilsTest do
  use ExUnit.Case, async: true

  import Rox.Utils

  test "encode / decode cycle" do
    input =
      %{name: "Bob"}

    output =
      input
      |> encode
      |> decode

    assert input == output
  end
end
