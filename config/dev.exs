use Mix.Config

config :trader, Trader.Repo,
  database: "trader_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :tinkoff_invest,
  token: System.fetch_env!("TINKOFF_TOKEN"),
  broker_account_id: System.fetch_env!("TINKOFF_BROKER_ACCOUNT_ID"),
  mode: :sandbox,
  logs_enabled: true
