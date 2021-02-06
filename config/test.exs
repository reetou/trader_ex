use Mix.Config

config :trader, Trader.Repo,
  database: "trader_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
