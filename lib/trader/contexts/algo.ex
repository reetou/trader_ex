defmodule Trader.Contexts.Algo do
  alias Trader.Algo.LongShortAverage
  require Logger
  
  def long_short_average(ticker) do
    result = LongShortAverage.decision(ticker)
    Logger.debug("Decision for #{ticker} by long short average: #{result}")
    result
  end
end