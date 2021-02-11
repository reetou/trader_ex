defmodule Trader.Telegram.Commands.Unregister do
  alias Trader.Contexts.User
  alias Trader.Schema
  alias Trader.Telegram
  require Logger

  @success """
  Удалены все упоминания о вашем счете, токене и бумагах
  """

  @command "/unregister"

  def command do 
    @command
  end

  def checks, do: [:register, :credentials, :account]

  def arguments, do: []

  def execute(%{message: %{text: text}} = update) do
    process(update)
  end

  def process(%{message: %{from: %{id: id}, chat: %{id: chat_id}}}) do
    case User.delete(%{telegram_id: id}) do 
      {:ok, _} -> 
        Telegram.send_message(chat_id, @success)
    end
  end
end
