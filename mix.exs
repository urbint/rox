defmodule Rox.Mixfile do
  use Mix.Project

  def project do
    [app: :rox,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     compilers: [:rustler] ++ Mix.compilers(),
     rustler_crates: rustler_crates(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:rustler, git: "https://github.com/hansihe/rustler.git", sparse: "rustler_mix"},
    ]
  end

  defp rustler_crates do
    [
      rox_nif: [path: "native/rox_nif", cargo: :system, default_features: false, features: [], mode: :release],
    ]
  end
end
