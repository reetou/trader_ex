defmodule Trader.Telegram.Commands.Instruments do
  alias Trader.Contexts.User
  alias Trader.Telegram
  alias Trader.Telegram.Commands.AddInstrument
  alias Trader.Utils
  require Logger

  @command "/all"

  @title """
  Отслеживаемые бумаги:

  """

  @no_positions_msg """
  Нет выбранных бумаг для отслеживания

  Добавьте бумагу командой #{AddInstrument.command()}
  """

  def command do
    @command
  end

  def checks, do: [:register, :credentials]

  def arguments, do: []

  def execute(%{message: %{text: text}} = update) do
    process(update)
  end

  def process(%{message: %{chat: %{id: chat_id}, from: %{id: user_id}}}) do
    txt =
      user_id
      |> User.by_telegram()
      |> User.get_instruments()
      |> format_instruments(chat_id)
    Telegram.send_message(chat_id, txt)
  end

  defp format_instruments(%{instruments: []}, chat_id) do
    @no_positions_msg
  end

  defp format_instruments(%{instruments: instruments}, chat_id) do
    instruments
    |> Enum.map(&Utils.format_instrument/1)
    |> Enum.join("\n")
    |> String.replace_prefix("", @title)
  end
end
