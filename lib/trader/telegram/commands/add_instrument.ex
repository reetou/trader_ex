defmodule Trader.Telegram.Commands.AddInstrument do
  alias Trader.Contexts.User
  alias Trader.Contexts.Market
  alias Trader.Telegram
  require Logger

  @command "/track"

  @init_msg """
  Добавьте бумагу командой:

  #{@command} _STOCK_TICKER_

  Пример для Apple:

  #{@command} AAPL
  """

  def command do
    @command
  end

  def checks, do: [:register, :credentials]

  def arguments, do: [:ticker]

  def execute(%{message: %{text: text}} = update) do
    process(update)
  end

  def process(%{message: %{text: @command, chat: %{id: chat_id}, from: %{id: user_id}}}) do
    Telegram.send_message(chat_id, @init_msg)
  end

  def process(%{message: %{text: @command <> " " <> ticker, chat: %{id: chat_id}, from: %{id: user_id}}}) do
    ticker = String.upcase(ticker)
    user = 
      user_id
      |> User.by_telegram()
      |> User.get_instruments()
      
    user  
    |> Map.fetch!(:instruments)
    |> Enum.find(fn %{ticker: t} -> t == ticker end)
    |> maybe_add_instrument(user, ticker, chat_id)
  end

  defp maybe_add_instrument(nil, user, ticker, chat_id) do
    case get_stock(ticker) do
      :error ->
        Telegram.send_message(chat_id, not_found(ticker))
      {:ok, stock} -> 
        {:ok, _} = User.add_instrument(user, ticker)
        Telegram.send_message(chat_id, success(ticker))
    end
  end

  defp maybe_add_instrument(_, _, ticker, chat_id) do
    Telegram.send_message(chat_id, success(ticker))
  end

  defp get_stock(ticker) do
    Market.stocks()
    |> Enum.find(fn %{ticker: t} -> t == ticker end)
    |> case do
      nil -> :error
      x -> {:ok, x}
    end
  end

  defp not_found(ticker) do
    "Бумага #{ticker} не найдена"
  end

  defp success(ticker) do
    "Бумага #{ticker} добавлена и будет отслеживаться ботом"
  end

  defp error(chat_id) do
    Telegram.send_message(chat_id, "Ошибка, проверьте правильность токена/счета и попробуйте снова")
  end
end
