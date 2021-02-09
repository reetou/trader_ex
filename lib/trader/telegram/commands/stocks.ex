defmodule Trader.Telegram.Commands.Stocks do
  alias Trader.Contexts.Market
  alias Trader.Contexts.User
  alias Trader.Telegram
  require Logger

  @no_instruments_msg """
  Нет выбранных бумаг для отслеживания
  Добавьте бумаги командой 123
  """

  def command do 
    "акции"
  end

  def check_register?, do: false
  def check_credentials?, do: false

  def execute(%{message: %{text: text}} = update) do
    process(update)
  end

  def process(%{message: %{from: %{id: user_id}, chat: %{id: chat_id}}}) do
    instruments = 
      user_id
      |> User.by_telegram()
      |> User.get_instruments()
      |> Map.fetch!(:instruments)
      |> Enum.map(fn %{figi: figi} -> figi end)
    txt = 
      Market.stocks()
      |> Enum.filter(fn %{figi: figi} -> figi in instruments end)
      |> format_stocks()
    Telegram.send_message(chat_id, txt)  
  end

  def format_stocks([]) do
    @no_instruments_msg
  end

  def format_stocks(stocks) do
    stocks
    |> Enum.map(&format_stock/1)
    |> Enum.join("\n")
  end

  def format_stock(%{ticker: ticker, name: name, min_price_increment: price, currency: currency}) do
    """
    - #{name} (#{ticker})
      Цена: #{price} #{currency}
    """
  end
end
