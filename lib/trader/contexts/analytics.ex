defmodule Trader.Contexts.Analytics do
  alias Trader.Contexts.Market
  alias TinkoffInvest.Model.Candle

  def average(figi, unit, amount, interval \\ "day") when unit in [:day, :week, :minute] do
    {from, to} = from_to(unit, amount)

    figi
    |> Market.candles(from, to, interval)
    |> candle_average()
    |> calc_average()
  end

  def from_to(unit, amount) do
    now = Timex.now("Europe/Moscow")

    from =
      now
      |> Timex.add(duration(unit, amount * -1))

    {from, now}
  end

  def candle_average([]), do: [-100, -100]

  def candle_average(x) when is_list(x), do: Enum.map(x, &candle_average/1)

  def candle_average(%Candle{h: h, l: l}) do
    (h + l) / 2
  end

  defp duration(:day, amount), do: Timex.Duration.from_days(amount)
  defp duration(:week, amount), do: Timex.Duration.from_weeks(amount)
  defp duration(:minute, amount), do: Timex.Duration.from_minutes(amount)
  defp duration(:second, amount), do: Timex.Duration.from_seconds(amount)
  defp duration(:millisecond, amount), do: Timex.Duration.from_milliseconds(amount)

  defp calc_average(values) do
    divide_by = length(values)
    Enum.sum(values) / divide_by
  end
end
