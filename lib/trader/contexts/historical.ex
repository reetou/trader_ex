defmodule Trader.Contexts.Historical do
  alias Trader.Algo.BuyWithin
  alias Trader.Contexts.Instruments
  alias Trader.Historical.DecisionCollector
  require Logger

  def buy_within(ticker, lots, 1, balance), do: buy_within(ticker, lots, :end, balance)

  def buy_within(ticker, lots, :end, _balance) do 
    Logger.warn("Execution finished #{ticker}, lots left: #{lots}")
    n = name("buy_within", ticker)
    {:ok, state} = DecisionCollector.state(n)
    :ok = DecisionCollector.reset(n)
    IO.inspect(state, label: "State is")
    :ok
  end
  
  def buy_within(ticker, lots, %DateTime{} = date, balance) do 
    n = name("buy_within", ticker)
    instrument = ticker |> Instruments.by_ticker()
    with %{o: o, c: c} <- Instruments.fetch_price(instrument, date) do 
      avg_price = maybe_avg_price(n)
      decision = BuyWithin.decision(instrument, lots, o, balance, date, avg_price)
      {:ok, %{lots: lots, balance: balance}} = DecisionCollector.collect(%{
        name: n,
        ticker: ticker,
        lots: lots,
        decision: decision,
        o: o, 
        c: c,
        balance: balance,
        date: date
      })
      %{lots: lots, balance: balance}
    else
      nil -> 
        Logger.warn("No price for date #{inspect date}, ignoring this day...")
        %{lots: lots, balance: balance, no_data: true}
    end
  end

  def buy_within(ticker, lots, back_days, balance) do 
    %{lots: lots, balance: balance} =
      back_days
      |> get_date()
      |> trade_dates()
      |> Enum.reduce(%{lots: lots, balance: balance}, fn date, acc -> 
        case acc do 
          %{no_data: true} -> acc
          _ -> buy_within(ticker, acc.lots, date, acc.balance)
        end
      end)
    Logger.debug("Going back to days: #{back_days - 1}")  
    buy_within(ticker, lots, back_days - 1, balance)
  end
  
  defp name(algo, ticker) do 
    "#{algo}_#{ticker}"
  end

  defp get_date(back_days) do 
    "Etc/UTC"
    |> Timex.now()
    |> Timex.shift(days: back_days * -1)
    |> Timex.beginning_of_day()
    |> Timex.shift(hours: 7)
    |> DateTime.truncate(:second)
  end

  defp trade_dates(from) do 
    # 09:05 - 22:30 UTC
    205..930
    |> Enum.take_every(20)
    |> Enum.map(fn min -> 
      Timex.shift(from, minutes: min)
    end)
  end

  defp maybe_avg_price(name) do 
    case DecisionCollector.state(name) do 
      {:ok, %{average_lot_price: price}} -> price
      _ -> nil
    end
  end
end