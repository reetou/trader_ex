defmodule Trader.Contexts.Analytics do
  alias Trader.Contexts.Market
  alias TinkoffInvest.Model.Candle
  alias Trader.Utils

  def average(figi, {from, to}, interval) do 
    do_average(figi, from, to, interval)
  end

  def average(figi, unit, amount, interval \\ "day") when unit in [:day, :week, :minute] do
    {from, to} = from_to(unit, amount)

    do_average(figi, from, to, interval)
  end

  def from_to(unit, amount) do
    now = Timex.now("Europe/Moscow")

    from =
      now
      |> Timex.add(Utils.duration(unit, amount * -1))

    {from, now}
  end

  def from_to(now, unit, amount) do
    from =
      now
      |> Timex.add(Utils.duration(unit, amount * -1))

    {from, now}
  end

  def candle_average([]), do: [-100, -100]

  def candle_average(x) when is_list(x), do: Enum.map(x, &candle_average/1)

  def candle_average(%Candle{h: h, l: l}) do
    (h + l) / 2
  end

  defp do_average(figi, from, to, interval) do 
    figi
    |> Market.candles(from, to, interval)
    |> candle_average()
    |> calc_average()
  end

  defp calc_average(values) do
    divide_by = length(values)
    Enum.sum(values) / divide_by
  end
end
