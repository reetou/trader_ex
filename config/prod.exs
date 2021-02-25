use Mix.Config

config :trader, Trader.Repo,
  database: "trader_prod",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :tinkoff_invest,
  token: "mytoken",
  broker_account_id: "mybroker",
  mode: :sandbox,
  logs_enabled: false