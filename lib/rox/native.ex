defmodule Rox.Native do
  use Rustler, otp_app: :rox, crate: "rox_nif"

  def open(_, _, _), do: raise "Nif not loaded"
  def count(_), do: raise "Nif not loaded"
  def create_cf(_, _, _), do: raise "Nif not loaded"
  def put(_, _, _, _), do: raise "Nif not loaded"
  def put_cf(_, _, _, _, _), do: raise "Nif not loaded"
  def get(_, _, _), do: raise "Nif not loaded"
end
