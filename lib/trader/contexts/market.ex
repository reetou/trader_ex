defmodule Trader.Contexts.Market do
  alias TinkoffInvest.Market
  alias Trader.Contexts.Cache
  require Logger

  @cache_key "stocks"
  def stocks do
    Cache.maybe_from_cache(@cache_key, &Market.stocks/0)
  end

  @cache_key "etfs"
  def etfs do
    Cache.maybe_from_cache(@cache_key, &Market.etfs/0)
  end

  @cache_key "bonds"
  def bonds do
    Cache.maybe_from_cache(@cache_key, &Market.bonds/0)
  end

  @cache_key "orderbook"
  def orderbook(figi, depth \\ 20) do
    Cache.maybe_from_cache(@cache_key, fn ->
      Market.orderbook(figi, depth)
    end)
  end

  def candles(figi, from, to, interval \\ "1min") do
    figi
    |> Market.candles(from, to, interval)
    |> TinkoffInvest.payload()
  end

  def search_figi(figi) do
    cache_key = "search_figi_#{figi}"

    Cache.maybe_from_cache(cache_key, fn ->
      Market.search_figi(figi)
    end)
  end

  def search_ticker(ticker) do
    cache_key = "search_ticker_#{ticker}"

    Cache.maybe_from_cache(cache_key, fn ->
      Market.search_ticker(ticker)
    end)
  end
end
