defmodule Trader.Algo.LongShortAverage do 
  alias Trader.Contexts.Analytics
  alias Trader.Contexts.Instruments
  require Logger

  @long_average_days 3

  @short_average_days 1

  @type operation_type() :: :buy | :sell
  
  @type decision_result() :: {operation_type(), integer()} | :ignore | {:limit, operation_type(), integer(), float()}

  @spec decision(map(), integer(), float(), float(), DateTime.t()) :: decision_result()
  def decision(%{ticker: ticker, figi: figi}, lots, price, balance, date) do 
    to = date
    from = Timex.shift(to, days: -2)
    figi
    |> calculate({from, to})
    |> do_decision(%{ticker: ticker, lots: lots, price: price, balance: balance, date: date})
  end

  def calculate(figi, {_from, _to} = dates) do 
    long_average = get_long_average(figi, dates)
    short_average = get_short_average(figi, dates)
    figi
    |> do_calculate(long_average, short_average)
  end

  def do_decision({:increase, x}, %{lots: lots, price: price, balance: balance}) when x > 0 and x < 2 and lots == 0 and balance > price  do 
    {:buy, 1}
  end

  def do_decision({:increase, x}, %{ticker: ticker, lots: lots, price: price, balance: _balance, date: date}) when x > 2 and lots > 0 do 
    {:sell, lots}
  end

  def do_decision({:decrease, x}, %{lots: lots, price: _price, balance: _balance}) when x <= -5 and lots > 0 do 
    {:buy, 1}
  end

  def do_decision(x, %{lots: lots, price: price, balance: balance}) do 
    Logger.warn("Ignoring stock with result #{inspect x}, #{lots} lots with price #{price} and balance #{balance}")
    :ignore
  end

  defp do_calculate(figi, long_average, short_average) do
    increase = short_average - long_average
    percent_increase = increase / short_average * 100
    Logger.debug("#{figi}: Long average: #{long_average}, short average: #{short_average}, increase: #{percent_increase}%")
    case percent_increase do 
      x when x > 0 -> {:increase, x}
      x when x <= 0 -> {:decrease, x}
    end
  end

  def get_long_average(figi) do
    Analytics.average(figi, :minute, 30, "1min")
  end

  def get_short_average(figi) do
    Analytics.average(figi, :minute, 5, "1min")
  end

  def get_long_average(figi, {from, to}) do
    from = Timex.shift(from, days: @long_average_days * -1)
    Analytics.average(figi, {from, to}, "day")
  end

  def get_short_average(figi, {from, to}) do
    from = Timex.shift(from, days: @short_average_days * -1)
    Analytics.average(figi, {from, to}, "day")
  end
end