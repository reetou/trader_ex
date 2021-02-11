defmodule Trader.Telegram.Commands.Account do
  alias Trader.Telegram
  alias Trader.Contexts.User
  alias Trader.Telegram.Commands.Token
  require Logger

  @command "/info"

  def command do
    @command
  end

  def checks, do: [:register, :credentials, :account]

  def arguments, do: []

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
