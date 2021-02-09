defmodule Trader.Contexts.Instruments do
  alias Trader.Contexts.Market
  alias Trader.Schema.Instrument
  alias Trader.Schema.UserInstrument

  def fill_stocks do
    Market.stocks()
    |> Enum.map(&Map.from_struct/1)
    |> Enum.each(&Instrument.create/1)
    :ok
  end

  def by_figi(figi) do
    Instrument.by(figi: figi)
  end

  def by_ticker(ticker) do
    Instrument.by(ticker: ticker)
  end

  def watching_stocks_figi do
    UserInstrument.all_figi()
  end

  def fetch_watching_stocks_prices do
    {from, to} = from_to(12)
    watching_stocks_figi()
    |> Enum.each(fn figi -> 
      Market.candles(figi, from, to, "1min")
      |> List.last()
      |> update_stock_price()
    end)
    :ok
  end

  def update_stock_price(nil), do: nil

  def update_stock_price(%{figi: figi, o: o, l: l, h: h, c: c, time: time}) do
    figi
    |> by_figi()
    |> Instrument.update(%{
      o: o, 
      c: c,
      h: h,
      l: l,
      last_price_update: time
    })
  end

  defp from_to(amount) do
    now = Timex.now("Europe/Moscow")
    from =
      now
      |> Timex.shift(hours: amount * -1)

    {from, now}
  end
end