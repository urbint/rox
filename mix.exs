defmodule Rox.Mixfile do
  use Mix.Project

  def project do
    [app: :rox,
     version: "1.0.1",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     compilers: [:rustler] ++ Mix.compilers(),
     rustler_crates: rustler_crates(),
     package: package(),
     description: description(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger]]
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
      {:rustler, "~> 0.9.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:benchfella, "~> 0.3", only: :dev},
      {:faker, "~> 0.7", only: :dev},
      {:flow, "~> 0.11", only: :dev},
      {:gen_stage, "~> 0.11", only: :dev},
      {:dialyxir, "~> 0.5", only: :dev},
    ]
  end

  defp rustler_crates do
    [
      rox_nif: [path: "native/rox_nif", cargo: :system, default_features: false, features: [], mode: :release],
    ]
  end

  defp description do
     """
     Rust powered NIF bindings to Facebook's RocksDB
     """
  end

  defp package do
    [
      name: :rox,
      files: ["lib", "native/rox_nif/Cargo.*", "native/rox_nif/src", "mix.exs", "README.md", "History.md", "LICENSE"],
      maintainers: ["Ryan Schmukler"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/urbint/rox"}
    ]
  end
end
