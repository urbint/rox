defmodule Rox.Native do
  use Rustler, otp_app: :rox, crate: "rox_nif"

  @dialyzer {:nowarn_function, [__init__: 0,]}

  def open(_, _, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> {:ok, ""}
      2 -> {:error, "Invalid argument: Column family not found: Something"}
    end
  end

  def create_snapshot(_) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> {:ok, ""}
      2 -> {:error, ""}
    end
  end

  def count(_) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> 0
    end
  end

  def count_prefix(_, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> 0
    end
  end

  def count_prefix_cf(_, _, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> 0
    end
  end

  def count_cf(_, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> 0
    end
  end

  def create_cf(_, _, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> {:ok, ""}
      2 -> {:error, ""}
    end
  end

  def cf_handle(_, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> {:ok, ""}
      2 -> {:error, ""}
    end
  end

  def put(_, _, _, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> :ok
    end
  end

  def put_cf(_, _, _, _, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> :ok
    end
  end

  def get(_, _, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> {:ok, ""}
    end
  end

  def get_cf(_, _, _, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> {:ok, ""}
    end
  end

  def delete(_, _, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> :ok
    end
  end

  def delete_cf(_, _, _, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> :ok
    end
  end

  def iterate(_, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> {:ok, ""}
    end
  end

  def iterate_prefix(_, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> {:ok, ""}
    end
  end

  def iterate_cf(_, _, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> {:ok, ""}
    end
  end

  def iterate_cf_prefix(_, _, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> {:ok, ""}
    end
  end

  def iterator_next(_) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> {"", ""}
      2 -> :done
    end
  end

  def iterator_reset(_, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> :ok
    end
  end

  def batch_write(_, _) do
    case :erlang.phash2(1, 1) do
      0 -> raise "Nif not loaded"
      1 -> :ok
      2 -> {:error, ""}
    end
  end
end
