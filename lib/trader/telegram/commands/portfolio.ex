defmodule Trader.Telegram.Commands.Portfolio do
  alias Trader.Telegram
  alias Trader.Contexts.User
  alias Trader.Contexts.Portfolio
  alias Trader.Contexts.Instruments
  alias Trader.Utils
  alias Trader.Telegram.Commands.Token
  require Logger

  @command "/profile"

  def command do
    @command
  end

  def checks, do: [:register, :credentials, :account]

  def arguments, do: []

  def execute(%{message: %{text: text}} = update) do
    process(update)
  end

  def process(%{message: %{chat: %{id: chat_id}, from: %{id: user_id}}}) do
    case portfolio(user_id) do
      positions when is_list(positions) -> 
        txt =
          positions
          |> Instruments.from_positions()
          |> format_positions()
        Telegram.send_message(chat_id, txt)
      _ -> 
        Telegram.send_message(chat_id, "Ошибка, попробуйте позднее")
    end
  end

  defp portfolio(user_id) do
    user_id
    |> User.by_telegram()
    |> User.opts()
    |> Portfolio.positions()
    |> case do
      %{status_code: 200, payload: payload} -> payload
      e -> {:error, e}
    end
  end

  defp format_positions([]), do: "Нет купленных позиций"

  defp format_positions(positions) do
    positions
    |> Enum.map(&Utils.format_instrument/1)
    |> Enum.join("\n")
    |> header_msg()
  end

  defp header_msg(msg) do
    msg
    |> String.replace_prefix("", "Купленные бумаги:\n")
  end
end
