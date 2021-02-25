defmodule Trader.Telegram.Commands do
  require Logger
  alias Trader.Telegram
  alias Trader.Telegram.Commands.Register
  alias Trader.Telegram.Commands.Unregister
  alias Trader.Telegram.Commands.Account
  alias Trader.Telegram.Commands.Token
  alias Trader.Telegram.Commands.Instruments
  alias Trader.Telegram.Commands.AddInstrument
  alias Trader.Telegram.Commands.Buy
  alias Trader.Telegram.Commands.Sell
  alias Trader.Telegram.Commands.Balance
  alias Trader.Telegram.Commands.Portfolio
  alias Trader.Telegram.Commands.Algo
  alias Trader.Contexts.User

  @commands_map %{
    Register.command() => Register,
    Account.command() => Account,
    Token.command() => Token,
    Instruments.command() => Instruments,
    AddInstrument.command() => AddInstrument,
    Buy.command() => Buy,
    Balance.command() => Balance,
    Portfolio.command() => Portfolio,
    Unregister.command() => Unregister,
    Sell.command() => Sell,
    Algo.command() => Algo
  }

  @commands Enum.map(@commands_map, fn {k, v} -> k end)

  @command_not_found_msg """
  Команда не найдена, доступные команды:

  #{Enum.map(@commands, fn c -> c <> "\n" end)}
  """

  @invalid_chat_type_msg """
  Я боюсь конф, лучше пишите мне в личку
  """

  @not_registered_msg "Для использования команды нужно зарегистрироваться: #{Register.command()}"

  @no_account_msg "Счет не найден, введите команду #{Token.command()} для исправления"

  @no_credentials_msg "Для использования команды нужно создать аккаунт в Тинькофф.Инвестициях: введите команду #{Token.command()}"

  @error_messages %{
    no_account: @no_account_msg,
    not_registered: @not_registered_msg,
    no_credentials: @no_credentials_msg
  }

  @info_msg """
  Доступные команды:

  #{Enum.map(@commands, fn c -> c <> "\n" end)}
  """

  def match_message(%{message: %{text: "команды", chat: %{id: chat_id}}}) do
    Telegram.send_message(chat_id, @info_msg)
  end

  def match_message(%{message: %{chat: %{type: type, id: chat_id}}}) when type not in ["private"] do
    Telegram.send_message(chat_id, @invalid_chat_type_msg)
    false
  end

  def match_message(%{message: %{text: text}}) when text == nil do
    Logger.debug("Received non-text message, ignoring")
    false
  end

  def match_message(%{message: %{text: text}} = update) when text in @commands do
    handle_message(update)
    true
  end

  def match_message(
        %{
          message: %{
            message_id: msg_id,
            chat: %{type: type, id: chat_id},
            text: text,
          }
        } = update
      ) do
    case String.split(text, " ") do
      x when is_list(x) and length(x) > 1 -> 
        handle_message(update)
      _ -> 
        command_not_found(chat_id)
    end
    true
  end

  defp put_args(%{message: %{text: text}} = update, cmd_args_keys) do
    args = 
      text
      |> String.split()
      |> Enum.slice(1..10)
    cmd_args = 
      cmd_args_keys
      |> Enum.with_index()
      |> Enum.map(fn {k, idx} -> 
        {k, Enum.at(args, idx)}
      end)
    Logger.debug("Command: #{text}, args: #{inspect cmd_args}")  
    Map.put(update, :trader_args, cmd_args)
  end

  defp handle_message(
    %{
      message: %{
        message_id: msg_id,
        chat: %{type: type, id: chat_id},
        text: text,
        from: %{id: user_id, username: username}
      }
    } = update
  ) do
    cmd =
      text
      |> String.split(" ")
      |> List.first()
    Task.start(fn -> 
      User.maybe_update_telegram_username(user_id, username)
    end)
    with module when not is_nil(module) <- Map.get(@commands_map, cmd),
         :ok <- User.with_registered(%{telegram_id: user_id}, module),
         :ok <- User.with_credentials(%{telegram_id: user_id}, module),
         :ok <- User.with_valid_account(%{telegram_id: user_id}, module) do
      args = module.arguments()  
      update
      |> put_args(args)
      |> module.execute()
    else
      nil -> 
        command_not_found(chat_id)
      {:error, e} ->
        error_message(chat_id, e)
    end
  end

  defp command_not_found(chat_id) do
    Telegram.send_message(chat_id, @command_not_found_msg)
  end

  defp error_message(chat_id, code) do 
    case Map.get(@error_messages, code) do 
      msg when is_binary(msg) ->
        Telegram.send_message(chat_id, msg)
      _ when is_atom(code) -> 
        Telegram.send_message(chat_id, "Неизвестная ошибка: код: #{code}")  
      _ when is_atom(code) -> 
        Logger.error("Unhandled error: #{inspect code}")
        Telegram.send_message(chat_id, "Неизвестная ошибка")  
    end
  end
end
