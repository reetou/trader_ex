defmodule Trader.Contexts.Algo do
  alias Trader.Algo.LongShortAverage
  alias Trader.Algo.BuyWithin
  alias Trader.Contexts.Instruments
  alias Trader.Contexts.User
  alias Trader.Contexts.Portfolio
  alias Trader.Contexts.Orders
  alias Trader.Contexts.DecisionExecutor
  alias Trader.Schema
  require Logger

  @algo_funs %{
    "buy_within" => &BuyWithin.decision/6
  }

  def iterate_all do 
    Schema.UserAlgo.all_active()
    |> Enum.map(fn %{ticker: ticker, algo: algo, user_id: user_id} -> 
      %Schema.User{} = user = Schema.User.get(user_id)
      iterate(user, "USD", ticker, algo)
    end)
  end

  def iterate(user, currency, ticker, algo) do 
    user
    |> decide(currency, ticker, algo)
    |> DecisionExecutor.execute(user, ticker)
  end

  def decide(user, currency, ticker, algo) do 
    %{} = instrument = Instruments.by_ticker(ticker)
    now = DateTime.utc_now()
    %{o: price} = Instruments.fetch_price(instrument, now)
    Logger.debug("[#{ticker}] open price is #{price} #{currency}")
    balance = user_balance(user, currency)
    lots = user_lots(user, ticker)
    fun = Map.fetch!(@algo_funs, algo)
    bought_price = user_bought_price(user, ticker)
    fun.(instrument, lots, price, balance, now, bought_price)
  end

  defp user_bought_price(user, ticker) do 
    orders = Orders.order_history(user, ticker)
    bought_lots = lots_by_op(orders, "buy")
    sold_lots = lots_by_op(orders, "sell")
    lots = bought_lots - sold_lots
    avg_for_lots(orders, lots)
  end

  defp lots_by_op(orders, op) do 
    orders
    |> Enum.filter(fn %{operation_type: op_type} -> op_type == op end)
    |> Enum.map(fn %{executed_lots: lots} -> lots end)
    |> Enum.sum()
  end

  defp user_lots(user, ticker) do 
    user
    |> User.opts()
    |> Portfolio.positions()
    |> case do 
      %{payload: x} when is_list(x) -> x
      e -> raise "#{__MODULE__} Api error: #{inspect(e)}"
    end
    |> Enum.find(fn %{ticker: t} -> t == ticker end)
    |> Map.fetch!(:balance)
  end

  defp user_balance(user, currency) do 
    user
    |> User.opts()
    |> Portfolio.currencies()
    |> case do 
      %{payload: x} when is_list(x) -> x
      e -> raise "#{__MODULE__} Api error: #{inspect(e)}"
    end
    |> Enum.find(fn %{currency: c} -> c == currency end)
    |> Map.fetch!(:balance)
  end

  defp avg_for_lots(deals, lots) do 
    deals
    |> Enum.filter(fn %{operation_type: t} -> t == "buy" end)
    |> Enum.reverse()
    |> Enum.reduce({[], lots}, fn (%{o: price, executed_lots: l}, {vals, acc_lots} = acc) -> 
      case acc_lots do 
        x when x > 0 -> 
          {vals ++ [price], acc_lots - l}
        _ -> acc
      end
    end)
    |> Tuple.to_list()
    |> List.first()
    |> avg()
  end

  defp avg([]), do: nil

  defp avg(vals) do 
    Enum.sum(vals) / length(vals)
  end
end