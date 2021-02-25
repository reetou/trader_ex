use Mix.Config

config :trader,
  ecto_repos: [Trader.Repo]

config :nadia,
  token: System.fetch_env!("TELEGRAM_TOKEN")

config :trader, Trader.Scheduler,
  jobs: [
    # Every 2 seconds
    fetch_watching_stocks: [
      schedule: {:extended, "*/2"},
      task: {Trader.Contexts.Instruments, :fetch_watching_stocks_prices, []},
    ],
    iterate_algos: [
      schedule: "* * * * *",
      task: {Trader.Contexts.Algo, :iterate_all, []},
    ]
  ]
import_config "#{Mix.env()}.exs"
