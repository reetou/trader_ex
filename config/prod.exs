use Mix.Config

config :trader, Trader.Repo,
  database: "trader_prod",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
