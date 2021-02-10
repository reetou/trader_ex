defmodule Trader.Telegram.Commands.Balance do
  alias Trader.Telegram
  alias Trader.Contexts.User
  alias Trader.Contexts.Portfolio
  alias Trader.Contexts.Sandbox
  alias Trader.Telegram.Commands.Token
  require Logger

  @command "баланс"

  @init_msg """
  Чтобы установить баланс, напишите:
  
  #{@command} USD 500
  
  Чтобы проверить баланс, напишите:
  
  #{@command}
  """

  @wrong_mode_msg "Ошибка: Вы находитесь не в режиме песочницы"

  @success_msg "Баланс обновлен успешно"

  @bad_balance_msg "Неверное значение баланса"
  @bad_security_msg "Неизвестное название валюты"
  
  def command, do: @command

  def checks, do: [:register, :credentials]

  def arguments, do: [:security, :new_balance]

  def execute(%{message: %{text: text}} = update) do
    process(update)
  end

  def process(%{trader_args: [security: nil, new_balance: nil], message: %{chat: %{id: chat_id}, from: %{id: user_id}}}) do
    case get_balance(user_id) do
      {:ok, msg} -> Telegram.send_message(chat_id, msg)
      {:error, msg} -> Telegram.send_message(chat_id, msg)
    end
  end

  def process(%{trader_args: [security: security, new_balance: new_balance], message: %{chat: %{id: chat_id}, from: %{id: user_id}}}) do
    security = String.upcase(security)
    case set_balance(user_id, security, new_balance) do
      {:error, :wrong_mode} -> Telegram.send_message(chat_id, @wrong_mode_msg)
      {:error, :bad_balance} -> Telegram.send_message(chat_id, @bad_balance_msg)
      {:error, :bad_security} -> Telegram.send_message(chat_id, @bad_security_msg)
      {:error, %{message: message}} when is_binary(message) -> Telegram.send_message(chat_id, message)
      {:error, %{message: nil}} -> Telegram.send_message(chat_id, "Неизвестная ошибка")
      {:ok, _} -> 
        Telegram.send_message(chat_id, @success_msg)
        case get_balance(user_id) do
          {:ok, msg} -> Telegram.send_message(chat_id, msg)
          _ -> nil
        end
    end
  end

  def process(%{message: %{chat: %{id: chat_id}}}) do
    Telegram.send_message(chat_id, @init_msg)
  end

  defp parse_balance(value) do
    case Integer.parse(value) do
      {value, ""} -> {:ok, value}
      _ -> {:error, :bad_balance}
    end
  end

  defp parse_security(security) when security in ["RUB", "USD", "EUR"] do
    {:ok, security}
  end

  defp parse_security(_), do: {:error, :bad_security}

  defp set_balance(user_id, security, balance) do
    with {:ok, balance} <- parse_balance(balance),
         {:ok, security} <- parse_security(security) do
      user = User.by_telegram(user_id)
      opts = User.opts(user)  
      security
      |> Sandbox.set_currency_balance(balance, opts)
      |> case do
        %{message: _} = e -> {:error, e}
        %{} = currency -> {:ok, currency}
      end
    else
      {:error, _} = e -> e  
    end
  end

  defp get_balance(user_id) do
    user = 
      user_id
      |> User.by_telegram()
    user  
    |> User.opts()
    |> Portfolio.currencies()
    |> TinkoffInvest.payload()
    |> get_balance_msg(user)
  end

  defp get_balance_msg(%{message: message}, _), do: {:error, message}

  defp get_balance_msg(currencies, user) when is_list(currencies) do
    result =
      currencies
      |> Enum.map(&format_currency/1)
      |> Enum.join("\n")
      |> msg_footer(user)
      |> msg_header(user)
    {:ok, result}  
  end

  defp format_currency(%{balance: balance, currency: currency}) do
    """
    - #{balance} #{currency}
    """
  end 

  defp msg_header(msg, _) do
    x =
      """
      Ваши валютные балансы:

      """
    String.replace_prefix(msg, "", x)  
  end

  defp msg_footer(msg, %{mode: "sandbox"}) do
    x = 
      """
    
      Вы находитесь в режиме песочницы и можете пополнить свой баланс когда угодно

      Пример пополнения баланса:
      
      #{@command} USD 500
      """
    String.replace_suffix(msg, "", x)  
  end

  defp msg_footer(msg, _), do: msg
end
