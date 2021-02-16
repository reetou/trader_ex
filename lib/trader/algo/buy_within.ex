defmodule Trader.Algo.BuyWithin do 
  alias Trader.Contexts.Analytics
  alias Trader.Contexts.Instruments
  alias TinkoffInvest.HistoricalData
  alias Trader.Historical.HistoryCache
  alias Trader.Utils
  require Logger

  @moduledoc """
  Buy if min price by last 14 days (with day interval) is lower for less than 15%

  Sell when profit is >= 2% and > 80 cents
  """

  @interval "day"

  @time_period 14

  @lots_amount 5

  @max_increase 15

  @type operation_type() :: :buy | :sell
  
  @type decision_result() :: {operation_type(), integer()} | :ignore | {:limit, operation_type(), integer(), float()}
  
  @spec decision(map(), integer(), float(), float(), DateTime.t(), float()) :: decision_result()
  def decision(%{ticker: ticker, figi: figi}, lots, price, balance, date, bought_price) do 
    to = date
    from = Timex.shift(to, days: @time_period * -1)
    figi
    |> calculate(price, from, to)
    |> do_decision(%{ticker: ticker, lots: lots, price: price, balance: balance, date: date, bought_price: bought_price})
  end

  def calculate(figi, current_price, from, to) do 
    figi
    |> get_open_min_price(from, to)
    |> get_increase_percent(current_price)
  end

  defp get_open_min_price(figi, from, to) do 
    figi
    |> HistoryCache.load(from, to, @interval)
    |> Enum.map(fn %{o: o} -> 
      o
    end)
    |> Enum.min()
  end

  defp get_increase_percent(source_price, current_price) do 
    increase = current_price - source_price
    increase / current_price * 100
  end

  defp do_decision(x, %{ticker: ticker, lots: 0, price: price, balance: balance}) when x <= @max_increase and x > -5 do 
    if Utils.enough_money?(balance, price, @lots_amount) do 
      {:buy, @lots_amount}
    else
      Logger.warn("Not enough money: Ticker #{ticker}, balance: #{balance}")
      :ignore  
    end
  end

  defp do_decision(x, %{lots: lots, price: price, balance: balance, bought_price: bought_price}) when lots > 0 and not is_nil(bought_price) do 
    case get_increase_percent(bought_price, price) do 
      x when x >= 2 and price - bought_price > 0.8 -> {:sell, lots}
      _ -> :ignore
    end
  end

  defp do_decision(x, z) do 
    :ignore
  end

end