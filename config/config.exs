use Mix.Config

config :trader,
  ecto_repos: [Trader.Repo]

config :nadia,
  token: System.fetch_env!("TELEGRAM_TOKEN")

import_config "#{Mix.env()}.exs"
