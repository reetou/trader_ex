use Mix.Config

config :trader,
  ecto_repos: [Trader.Repo]

import_config "#{Mix.env()}.exs"
