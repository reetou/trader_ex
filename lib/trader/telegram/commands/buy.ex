defmodule Trader.Telegram.Commands.Buy do
  alias Trader.Contexts.User
  alias Trader.Contexts.Orders
  alias Trader.Contexts.Instruments
  alias Trader.Telegram
  alias Trader.Telegram.Commands.Portfolio
  require Logger

  @command "купи"

  @init_msg """
  Пример использования команды: купи _TICKER_ _LOTS_

  Например:

  купи aapl 5
  """

  @bad_lots_msg "Неверное значение количества лотов. Должно быть целым числом, например: 1"

  @success_msg "Покупка совершена успешно. Данные о покупке можно просмотреть командой #{Portfolio.command()}"

  @no_instrument_msg "Бумага не найдена"

  def command, do: @command

  def checks, do: [:register, :credentials]

  def arguments, do: [:ticker, :lots]

  def execute(update) do
    process(update)
  end

  def process(%{trader_args: [ticker: ticker, lots: lots], message: %{chat: %{id: chat_id}, from: %{id: user_id}}}) do
    case buy_stock(user_id, ticker, lots) do
      {:ok, order} -> success(chat_id, order)
      {:error, :bad_lots_amount} -> error(chat_id, @bad_lots_msg)
      {:error, %{payload: %{message: error_message}}} -> error(chat_id, error_message)
      {:error, %{payload: %{reject_reason: reject_reason}}} -> error(chat_id, reject_reason)
      {:error, :no_instrument} -> error(chat_id, @no_instrument_msg)
      {:error, :invalid_ticker} -> error(chat_id, @init_msg)
      {:error, :no_lots_amount} -> error(chat_id, @init_msg)
    end
  end
  
  def buy_stock(user_id, ticker, lots) do
    with %{} = user <- User.by_telegram(user_id),
         {:ok, lots} <- parse_lots(lots),
         {:ok, ticker} <- parse_ticker(ticker),
         {:ok, order} <- Orders.buy(user, ticker, lots) do
      {:ok, order}
    else
      {:error, _} = e -> e
    end
  end

  defp parse_ticker(nil), do: {:error, :invalid_ticker}

  defp parse_ticker(x) do
    x = String.upcase(x)
    case Instruments.by_ticker(x) do
      nil -> {:error, :no_instrument}
      %{} -> {:ok, x}
    end
  end

  defp parse_lots(nil), do: {:error, :no_lots_amount}

  defp parse_lots(lots) do
    case Integer.parse(lots) do
      {lots, ""} -> {:ok, lots}
      _ -> {:error, :bad_lots_amount}
    end
  end

  defp success(chat_id, _) do
    Telegram.send_message(chat_id, @success_msg)
  end 

  defp error(chat_id, msg) do
    Telegram.send_message(chat_id, """
    Ошибка:

    #{msg}
    """)
  end
end
