defmodule Trader.Telegram.Commands.Algo do
  alias Trader.Contexts.User
  alias Trader.Contexts.Market
  alias Trader.Telegram
  alias Trader.Algo.BuyWithin
  require Logger

  @command "/algo"

  @init_msg """
  Добавление/удаление алгоритма для бумаги

  #{@command} add _STOCK_TICKER_ _ALGO_NAME_

  #{@command} remove _STOCK_TICKER_ _ALGO_NAME_

  Пример:

  #{@command} add AAPL buy_within

  Когда алгоритм добавлен и активен, бот будет ежедневно торговать следуя выбранному алгоритму

  Список используемых алгоритмов и бумаг:

  #{@command} all

  Возможные алгоритмы:

  #{BuyWithin.name()} - #{BuyWithin.description()}
  """

  def command do
    @command
  end

  def checks, do: [:register, :credentials, :account]

  def arguments, do: [:action, :ticker, :algo]

  def execute(%{message: %{text: text}} = update) do
    process(update)
  end

  def process(%{trader_args: [action: "all", ticker: nil, algo: nil], message: %{chat: %{id: chat_id}, from: %{id: user_id}}}) do
    msg = 
      %{telegram_id: user_id}
      |> User.algos()
      |> Enum.map(&format_algo/1)
      |> Enum.join("")
      |> case do 
        "" -> "Нет добавленных алгоритмов"
        x -> x
      end

    Telegram.send_message(chat_id, msg)  
  end

  def process(%{trader_args: [action: "add", ticker: ticker, algo: algo], message: %{chat: %{id: chat_id}, from: %{id: user_id}}}) when is_binary(ticker) and is_binary(algo) do
    ticker = String.upcase(ticker)
    :ok = User.add_algo(%{telegram_id: user_id, ticker: ticker, algo: algo})
    Telegram.send_message(chat_id, "Добавлено успешно")
  end

  def process(%{trader_args: [action: "remove", ticker: ticker, algo: algo], message: %{chat: %{id: chat_id}, from: %{id: user_id}}}) when is_binary(ticker) and is_binary(algo) do
    ticker = String.upcase(ticker)
    :ok = User.remove_algo(%{telegram_id: user_id, ticker: ticker, algo: algo})
    Telegram.send_message(chat_id, "Удалено успешно")
  end

  def process(%{message: %{chat: %{id: chat_id}}}) do
    Telegram.send_message(chat_id, @init_msg)
  end

  defp format_algo(%{ticker: ticker, algo: algo, active: active, balance_limit: balance_limit}) do 
    """
    
    - #{algo} для #{ticker}
      Активен: #{format_bool(active)}
      Лимит: #{balance_limit} 

    """
  end

  defp format_bool(true), do: "да"
  defp format_bool(false), do: "нет"
end
