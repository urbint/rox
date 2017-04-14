defmodule RoxBench do
  use Benchfella

  @sample_record %{name: "Bob", age: 38, favorite_color: "Blue", gender: :male, is_likeable: false, pets: [%{name: "Woof", species: :dog}]}

  setup_all do
    :ok =
      Application.ensure_started(:faker)
    
    {:ok, db, cfs} =
      Rox.open("./bench.rocksdb", [create_if_missing: true, auto_create_column_families: true], ["a", "b", "c"])

    {:ok, %{db: db, cfs: cfs, default_cf: cfs["a"]}}
  end

  teardown_all _ do
    File.rm_rf!("./bench.rocksdb")
  end

  bench "random_writes" do
    Rox.put(bench_context.default_cf, random_key(), random_record())
  end

  defp random_key() do
    :crypto.rand_uniform(1, 10_000_000)
    |> Integer.to_string()
  end

  defp random_record() do
    num_pets =
      :crypto.rand_uniform(0, 3)
    
    %{
      name: Faker.Name.name(),
      age: :crypto.rand_uniform(20, 50),
      favorite_color: Faker.Color.name(),
      description: Faker.Lorem.words(10),
      profile_url: Faker.Internet.image_url(),
      pets: Enum.map(0..num_pets, fn _ -> random_pet() end)
    }
  end

  defp random_pet() do
    %{
      name: Faker.Name.first_name(),
      age: :crypto.rand_uniform(1, 7),
    }
  end
end
