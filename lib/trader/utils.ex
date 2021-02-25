defmodule Trader.Utils do
  def fun_capture({mod, fun, arity}) do
    Function.capture(mod, fun, arity)
  end

  def format_price(nil, _) do
    "--"
  end

  def format_price(value, currency) do
    "#{value} #{currency}"
  end
  
  def format_time(nil) do
    "Еще не обновлялось"
  end

  def format_time(time) do
    now = Timex.now()
    "#{Timex.diff(now, time, :minutes)} мин назад"
  end

  def format_instrument(%{name: name, ticker: ticker, instrument: %{o: o, c: c, last_price_update: time, currency: currency}}) do
    """
    - #{name} (#{ticker})
      Продается за #{format_price(c, currency)}
      Покупается за #{format_price(o, currency)}
      Последнее обновление: #{format_time(time)} 
    """
  end

  def format_instrument(%{balance: balance, blocked: blocked, name: name, ticker: ticker, o: o, c: c, last_price_update: time, currency: currency}) do
    """
    - #{name} (#{ticker})
      Лотов: #{balance}
      Заблокировано лотов: #{blocked}
      Продается за #{format_price(c, currency)}
      Покупается за #{format_price(o, currency)}
      Последнее обновление: #{format_time(time)} 
    """
  end

  def format_instrument(%{name: name, ticker: ticker, o: o, c: c, last_price_update: time, currency: currency}) do
    """
    - #{name} (#{ticker})
      Продается за #{format_price(c, currency)}
      Покупается за #{format_price(o, currency)}
      Последнее обновление: #{format_time(time)} 
    """
  end

  def duration(:day, amount), do: Timex.Duration.from_days(amount)
  def duration(:week, amount), do: Timex.Duration.from_weeks(amount)
  def duration(:minute, amount), do: Timex.Duration.from_minutes(amount)
  def duration(:second, amount), do: Timex.Duration.from_seconds(amount)
  def duration(:millisecond, amount), do: Timex.Duration.from_milliseconds(amount)

  def enough_money?(balance, price, lots) do 
    cond do 
      price * lots < balance -> true
      true -> false
    end
  end

  @doc """
  
  Returns boolean whether can trade or not

      iex>date = ~U[2021-02-25 06:55:16.144828Z]
      ...>Trader.Utils.can_trade?(date)
      false

      iex>date = ~U[2021-02-25 07:01:16.144828Z]
      ...>Trader.Utils.can_trade?(date)
      true

      iex>date = ~U[2021-02-25 15:55:16.144828Z]
      ...>Trader.Utils.can_trade?(date)
      true

      iex>date = ~U[2021-02-25 22:39:46.144828Z]
      ...>Trader.Utils.can_trade?(date)
      true

      iex>date = ~U[2021-02-25 22:41:16.144828Z]
      ...>Trader.Utils.can_trade?(date)
      false

      iex>date = ~U[2021-02-26 15:55:16.144828Z]
      ...>Trader.Utils.can_trade?(date) # Friday
      true

      iex>date = ~U[2021-02-27 15:55:16.144828Z]
      ...>Trader.Utils.can_trade?(date) # Saturday
      false

      iex>date = ~U[2021-02-28 15:55:16.144828Z]
      ...>Trader.Utils.can_trade?(date) # Sunday
      false

      iex>date = ~U[2021-03-01 15:55:16.144828Z]
      ...>Trader.Utils.can_trade?(date) # Monday
      true
  """
  def can_trade?(date) do 
    trade_start = 
      date
      |> Timex.beginning_of_day()
      |> Timex.shift(hours: 7)
      |> Timex.shift(minutes: 1)

    trade_end = 
      date
      |> Timex.beginning_of_day()
      |> Timex.shift(hours: 23)
      |> Timex.shift(minutes: -20)  

    Timex.between?(date, trade_start, trade_end) and Timex.weekday(date) < 6
  end
end
