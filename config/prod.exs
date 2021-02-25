use Mix.Config

config :tinkoff_invest,
  token: System.fetch_env!("TINKOFF_TOKEN"),
  broker_account_id: System.fetch_env!("TINKOFF_BROKER_ACCOUNT_ID"),
  mode: :sandbox,
  logs_enabled: false

config :trader, Trader.Repo,
  log: false,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
