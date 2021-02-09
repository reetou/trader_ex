defmodule Trader.Telegram.Commands.Portfolio do
  alias Trader.Telegram
  alias Trader.Contexts.User
  alias Trader.Contexts.Portfolio
  require Logger

  def command do
    "портфолио"
  end

  def check_register?, do: true
  def check_credentials?, do: true

  def execute(%{message: %{text: text}} = update) do
    process(update)
  end

  def process(%{message: %{chat: %{id: chat_id}, from: %{id: user_id}}}) do
    user_id
    |> User.by_telegram()
    |> User.opts()
    |> Portfolio.positions()
    |> case do
      %{status_code: 200, payload: payload} -> 
        txt = format_positions(payload)
        Telegram.send_message(chat_id, txt)
      _ -> 
        Telegram.send_message(chat_id, "Ошибка, попробуйте позднее")
    end
  end

  defp format_positions([]), do: "Нет купленных позиций"

  defp format_positions(positions) do
    positions
    |> Enum.map(&format_position/1)
    |> Enum.join("\n")
  end

  defp format_position(%{name: name, balance: balance, blocked: blocked, average_position_price: %{currency: currency, value: avg_price}}) do 
    """
    - #{name}
    - Баланс: #{balance}
    - Заблокировано: #{blocked}
    - Средняя цена: #{avg_price} #{currency}

    ===

    """
  end
end
