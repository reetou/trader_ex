defmodule Trader.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Trader.Telegram
  alias Trader.Contexts.Instruments

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Trader.Worker.start_link(arg)
      # {Trader.Worker, arg}
      {Trader.Repo, []},
      {Trader.Scheduler, []},
      {Trader.Historical.DecisionCollector, [name: Trader.Historical.DecisionCollector]},
      {Trader.Historical.HistoryCache, [name: Trader.Historical.HistoryCache]},
      {Telegram.Poller, []},
      {Telegram.Matcher, []},
      {Trader.UserRequest, [name: Trader.UserRequest]},
      {Cachex, name: :api_cache}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Trader.Supervisor]
    result = Supervisor.start_link(children, opts)

    init()
    
    result
  end

  defp init do
    :ok = Instruments.fill_stocks()
    :ok = Instruments.fetch_watching_stocks_prices()
  end
end
