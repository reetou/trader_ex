defmodule Trader.Historical.DecisionCollector do 
  use GenServer
  require Logger

  @log_file_dir "log_files"

  def init(_) do
    Logger.debug("Init #{__MODULE__}")
    {:ok, %{}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def handle_call({:collect, {name, ticker, lots, decision, o, c, balance} = x, date}, _from, state) do 
    result = 
      state
      |> Map.get(name, %{
        init_balance: balance, 
        balance: balance, 
        lots: lots, 
        deals: [],
        suffix: DateTime.utc_now() |> DateTime.to_unix()
      })
    result = 
      result 
      |> last_price(x)
      |> handle_lots(decision, lots)
      |> handle_deal(decision)
      |> handle_balance(decision, o, c)
      |> average_lot_price()
      |> final_balance()
      |> deals_count()

    x
    |> log_intent()
    |> log_file(result, date)  

    {:reply, {:ok, result}, Map.put(state, name, result)}
  end

  def handle_call({:state, name}, _from, state) do 
    {:reply, {:ok, Map.get(state, name)}, state}
  end

  def handle_call({:reset, name}, _from, state) do 
    state = Map.drop(state, [name])
    {:reply, :ok, state}
  end

  def collect(%{name: name, ticker: ticker, lots: lots, decision: decision, o: o, c: c, balance: balance, date: date}) do 
    GenServer.call(__MODULE__, {:collect, {name, ticker, lots, decision, o, c, balance}, date})
  end 

  def reset(name) do 
    GenServer.call(__MODULE__, {:reset, name})
  end

  def state(name) do 
    GenServer.call(__MODULE__, {:state, name})
  end

  defp last_price(data, {_, _, _, _, o, c, _}) do 
    Map.put(data, :last_price, %{
      o: o,
      c: c
    })
  end

  defp log_file({_, _, _, :ignore, _, _, _} = x, _, _), do: x

  defp log_file({name, ticker, lots, op, o, c, _} = x, %{suffix: suffix, balance: balance}, date) do 
    File.mkdir_p!(@log_file_dir)
    name = @log_file_dir <> "/" <> name <> "_#{suffix}"
    File.touch!(name)
    content = File.read!(name)
    File.write!(name, content <> "\n" <> "[#{DateTime.to_iso8601(date)}]: [#{ticker}] #{inspect op} for lots #{lots}, o: #{o}, c: #{c}, balance -> #{balance}")
    x
  end

  defp log_intent({name, ticker, _, :ignore, _, _, _} = x), do: x
  defp log_intent({name, ticker, _, _, _, _, _} = x) do 
    Logger.debug("#{name}: [#{ticker}] #{intent(x)}")
    x
  end

  defp intent({_, _, _, {:buy, x}, o, _, _}) do 
    "Buy #{x} for #{o}"
  end

  defp intent({_, _, _, {:sell, x}, _, c, _}) do 
    "Sell #{x} for #{c}"
  end

  defp intent({_, _, _, d, _, c}) do 
    "unhandled decision: #{inspect d}"
  end

  defp handle_balance(data, :ignore, _, _), do: data

  defp handle_balance(%{balance: balance} = data, {:buy, x}, o, _) do 
    Map.put(data, :balance, balance - (o * x))
  end

  defp handle_balance(%{balance: balance} = data, {:sell, x}, _, c) do 
    Map.put(data, :balance, balance + (c * x))
  end

  defp handle_balance(data, {:limit, op, lots, price}, _, _) do 
    handle_balance(data, {op, lots}, price, price)
  end

  defp handle_deal(data, :ignore), do: data
  
  defp handle_deal(%{deals: deals, last_price: last_price} = data, d) do 
    d = Tuple.append(d, last_price)
    deals = deals ++ List.wrap(d)
    Map.put(data, :deals, deals)
  end

  defp handle_lots(data, {:buy, x}, lots) do 
    Map.put(data, :lots, lots + x)
  end

  defp handle_lots(data, {:sell, x}, lots) do 
    Map.put(data, :lots, lots - x)
  end

  defp handle_lots(data, {:limit, op, x, _}, lots) do 
    handle_lots(data, {op, x}, lots)
  end

  defp handle_lots(data, :ignore, lots) do 
    Map.put(data, :lots, lots)
  end

  defp final_balance(%{lots: lots, balance: balance, average_lot_price: price} = data) when lots > 0 do 
    final_balance = lots * price + balance
    Map.put(data, :final_balance, final_balance)
  end

  defp final_balance(x), do: x

  defp deals_count(%{deals: deals} = data) do 
    Map.put(data, :deals_count, length(deals))
  end

  defp average_lot_price(%{deals: deals} = data) do 
    bought_lots = lots_by_type(deals, :buy)
    sold_lots = lots_by_type(deals, :sell)
    lots = bought_lots - sold_lots
    avg_price = avg_for_lots(deals, lots)
    Map.put(data, :average_lot_price, avg_price)  
  end

  defp avg_for_lots(_, lots) when lots <= 0 do 
    nil
  end

  defp avg_for_lots(deals, lots) do 
    deals
    |> Enum.filter(fn {t, _, _} -> 
      t == :buy
    end)
    |> Enum.reverse()
    |> Enum.reduce({[], lots}, fn ({t, l, %{o: price}}, {vals, acc_lots} = acc) -> 
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

  defp lots_by_type(deals, type) do 
    deals
    |> Enum.filter(fn {t, _, _} -> 
      t == type
    end)
    |> Enum.map(fn {_, lots, _} -> 
      lots
    end)
    |> Enum.sum()
  end
end 