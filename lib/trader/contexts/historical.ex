defmodule Trader.Contexts.Historical do
  alias Trader.Algo.LongShortAverage
  alias Trader.Contexts.Instruments
  alias Trader.Historical.DecisionCollector
  require Logger

  def long_short_average(ticker, lots, back_days, balance \\ 2000)

  def long_short_average(ticker, lots, 1 = back_days, balance) do 
    Logger.warn("Execution finished #{ticker}, lots left: #{lots}")
    date = get_date(back_days)
    n = name("long_short_average", ticker)
    {:ok, state} = DecisionCollector.state(n)
    :ok = DecisionCollector.reset(n)
    IO.inspect(state, label: "State is")
    :ok
  end
  
  def long_short_average(ticker, lots, back_days, balance) do 
    n = name("long_short_average", ticker)
    date = get_date(back_days)
    instrument = 
      ticker
      |> Instruments.by_ticker()
    with %{o: o, c: c} <- Instruments.fetch_price(instrument, date) do 
      decision = instrument |> LongShortAverage.decision(lots, o, balance, date)
      {:ok, %{lots: lots, balance: balance}} = DecisionCollector.collect(%{
        name: n,
        ticker: ticker,
        lots: lots,
        decision: decision,
        o: o, 
        c: c,
        balance: balance
      })
      long_short_average(ticker, lots, back_days - 1, balance)
    else
      nil -> 
        Logger.warn("No price for date #{inspect date}, ignoring this day...")
        long_short_average(ticker, lots, back_days - 1, balance)
    end
  end
  
  defp name(algo, ticker) do 
    "#{algo}_#{ticker}"
  end

  defp get_date(back_days) do 
    "Europe/Moscow"
    |> Timex.now()
    |> Timex.shift(days: back_days * -1)
  end
end