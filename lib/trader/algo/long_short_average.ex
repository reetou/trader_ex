defmodule Trader.Algo.LongShortAverage do 
  alias Trader.Contexts.Instruments
  alias Trader.Contexts.Analytics
  require Logger

  @no_value -100
  

  def decision(ticker) do
    ticker
    |> Instruments.by_ticker()
    |> Map.fetch!(:figi)
    |> calculate()
    |> case do
      {:increase, x} when x > 3 -> :buy
      _ -> :ignore
    end
  end
  
  def calculate(figi) do
    long_average = get_long_average(figi)
    short_average = get_short_average(figi)
    cond do 
      long_average == @no_value or short_average == @no_value ->
        Logger.warn("Ignoring #{figi}, no data for one of the intervals")
        :no_data
      true ->
        do_calculate(figi, long_average, short_average)  
    end
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

  defp get_long_average(figi) do
    Analytics.average(figi, :minute, 30, "1min")
  end

  defp get_short_average(figi) do
    Analytics.average(figi, :minute, 5, "1min")
  end
end