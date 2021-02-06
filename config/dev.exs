use Mix.Config

config :trader, Trader.Repo,
  database: "trader_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
