use Mix.Config

config :tinkoff_invest,
  token: "mytoken",
  broker_account_id: "mybroker",
  mode: :sandbox,
  logs_enabled: false

config :trader, Trader.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
