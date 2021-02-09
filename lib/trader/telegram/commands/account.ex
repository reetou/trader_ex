defmodule Trader.Telegram.Commands.Account do
  alias Trader.Telegram
  alias Trader.Contexts.User
  alias Trader.Telegram.Commands.Token
  require Logger

  def command do
    "аккаунт"
  end

  def check_register?, do: true
  def check_credentials?, do: true

  def execute(%{message: %{text: text}} = update) do
    process(update)
  end

  def process(%{message: %{chat: %{id: chat_id}, from: %{id: user_id}}}) do
    acc_id =
      user_id
      |> User.by_telegram()
      |> Map.fetch!(:broker_account_id)
    Telegram.send_message(chat_id, """
    Аккаунт настроен корректно

    Используется счет: #{acc_id}
    """)
  end
end
