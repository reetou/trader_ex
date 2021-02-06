defmodule Trader.MixProject do
  use Mix.Project

  def project do
    [
      app: :trader,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Trader.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:tinkoff_invest, "~> 0.1.0"},
      {:cachex, "~> 3.3"},
      # Test
      {:mock, "~> 0.3.0", only: :test}
    ]
  end
end
