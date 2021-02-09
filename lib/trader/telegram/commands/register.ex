defmodule Trader.Telegram.Commands.Register do
  alias Trader.Contexts.User
  alias Trader.Schema
  alias Trader.Telegram
  alias Trader.Telegram.Commands.Account
  require Logger

  @already_registered_msg "Вы уже зарегистрированы. Введите команду #{Account.command()} для продолжения"
  @register_success "Успех! Вы зарегистрированы. Введите команду #{Account.command()} для продолжения"

  def command do 
    "регистрация"
  end

  def check_register?, do: false
  def check_credentials?, do: false

  def execute(%{message: %{text: text}} = update) do
    process(update)
  end

  def process(%{message: %{from: %{id: id, username: username}, text: text, chat: %{id: chat_id}} = message} = update) do
    case User.create_from_telegram(%{telegram_id: id, telegram_username: username}) do 
      {:error, :already_registered} -> 
        Telegram.send_message(chat_id, @already_registered_msg)
      %Schema.User{} ->  
        Telegram.send_message(chat_id, @register_success)
    end
  end
end
