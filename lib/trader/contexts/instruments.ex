defmodule Trader.Contexts.Instruments do
  alias Trader.Contexts.Market
  alias Trader.Historical.HistoryCache
  alias Trader.Schema.Instrument
  alias Trader.Schema.UserInstrument
  alias TinkoffInvest.HistoricalData

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

  def fetch_price(%Instrument{} = instrument, date) do 
    {from, to} = from_to(date, 1)
    instrument
    |> Map.fetch!(:figi)
    |> HistoryCache.load(from, to, "1min")
    |> Enum.filter(fn %{time: time} ->
      before_or_equal?(time, to)
    end)
    |> Enum.to_list()
    |> List.last()
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

  def from_positions(positions) do
    lots_map = 
      positions
      |> Enum.map(fn %{ticker: ticker} = x -> {ticker, x} end)
      |> Map.new()
    positions
    |> Enum.map(fn %{ticker: ticker} -> ticker end)
    |> Instrument.by_tickers()
    |> Enum.map(&Map.from_struct/1)
    |> Enum.map(fn %{ticker: ticker} = x -> 
      lots_map
      |> Map.get(ticker)
      |> merge_position(x)
    end)
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

  defp from_to(date, amount) do
    to = date
    from =
      to
      |> Timex.shift(hours: amount * -1)

    {from, to}
  end

  defp from_to(amount) do
    Timex.now("Etc/UTC")
    |> from_to(amount)
  end

  defp merge_position(position, instrument) do 
    Map.merge(position, instrument)
  end

  defp before_or_equal?(date_string, %DateTime{} = date) do 
    date = Timex.shift(date, minutes: 1)
    {:ok, parsed} = Timex.parse(date_string, "{ISO:Extended}")
    Timex.before?(parsed, date)
  end
end