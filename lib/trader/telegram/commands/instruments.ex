defmodule Trader.Telegram.Commands.Instruments do
  alias Trader.Contexts.User
  alias Trader.Telegram
  alias Trader.Telegram.Commands.AddInstrument
  require Logger

  @title """
  Отслеживаемые бумаги:

  """

  @no_positions_msg """
  Нет выбранных бумаг для отслеживания

  Добавьте бумагу командой #{AddInstrument.command()}
  """

  def command do
    "бумаги"
  end

  def check_register?, do: true
  def check_credentials?, do: true

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
    |> Enum.map(&format_instrument/1)
    |> Enum.join("\n")
    |> String.replace_prefix("", @title)
  end

  defp format_instrument(%{name: name, ticker: ticker, instrument: %{o: o, c: c, last_price_update: time, currency: currency}}) do
    """
    - #{name} (#{ticker})
      Продается за #{format_price(c, currency)}
      Покупается за #{format_price(o, currency)}
      Последнее обновление: #{format_time(time)} 
    """
  end

  defp format_price(nil, _) do
    "--"
  end

  defp format_price(value, currency) do
    "#{value} #{currency}"
  end
  
  defp format_time(nil) do
    "Еще не обновлялось"
  end

  defp format_time(time) do
    now = Timex.now()
    "#{Timex.diff(now, time, :minutes)} мин назад"
  end

  defp error(chat_id) do
    Telegram.send_message(chat_id, "Ошибка, проверьте правильность токена/счета и попробуйте снова")
  end
end
