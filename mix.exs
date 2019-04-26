defmodule Rox.Mixfile do
  use Mix.Project

  def project do
    [
      app: :rox,
      version: "2.3.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: rustler_crates(),
      package: package(),
      description: description(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger]]
  end

  # Type "mix help deps" for more examples and options
  defp deps do
    [
      # Rust NIFs
      {:rustler, "~> 0.18"},

      # Doc generation
      {:ex_doc, "~> 0.18", only: :dev},

      # Benchmarking
      {:benchfella, "~> 0.3.0", only: :dev},

      # Generate fake data
      {:faker, "~> 0.7", only: :dev},

      # Computational flows
      {:flow, "~> 0.14", only: :dev},

      # Producers and consumers
      {:gen_stage, "~> 0.14", only: :dev},

      # Dialyzer support
      {:dialyxir, "~> 1.0.0-rc.1", only: :dev, runtime: false}
    ]
  end

  defp rustler_crates do
    [
      rox_nif: [
        path: "native/rox_nif",
        cargo: :system,
        default_features: false,
        features: [],
        mode: :release
      ]
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
      files: [
        "lib",
        "native/rox_nif/Cargo.*",
        "native/rox_nif/src",
        "mix.exs",
        "README.md",
        "History.md",
        "LICENSE"
      ],
      maintainers: ["Griffin Smith"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/urbint/rox"}
    ]
  end
end
