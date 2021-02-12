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

  def handle_call({:collect, {name, ticker, lots, decision, o, c, balance} = x}, _from, state) do 
    result = 
      state
      |> Map.get(name, %{
        init_balance: balance, 
        balance: balance, 
        lots: lots, 
        deals: [],
        suffix: DateTime.utc_now() |> DateTime.to_unix()
      })
    x
    |> log_intent()
    |> log_file(result.suffix)
    result = 
      result 
      |> handle_lots(decision, lots)
      |> handle_deal(decision)
      |> handle_balance(decision, o, c)
      |> last_price(x)

    {:reply, {:ok, result}, Map.put(state, name, result)}
  end

  def handle_call({:state, name}, _from, state) do 
    {:reply, {:ok, state}, state}
  end

  def handle_call({:reset, name}, _from, state) do 
    state = Map.drop(state, [name])
    {:reply, :ok, state}
  end

  def collect(%{name: name, ticker: ticker, lots: lots, decision: decision, o: o, c: c, balance: balance}) do 
    GenServer.call(__MODULE__, {:collect, {name, ticker, lots, decision, o, c, balance}})
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

  defp log_file({_, _, _, :ignore, _, _, _} = x, _), do: x

  defp log_file({name, ticker, lots, op, o, c, _} = x, suffix) do 
    File.mkdir_p!(@log_file_dir)
    name = @log_file_dir <> "/" <> name <> "_#{suffix}"
    File.touch!(name)
    content = File.read!(name)
    File.write!(name, content <> "\n" <> "[#{ticker}] #{inspect op} for lots #{lots}, o: #{o}, c: #{c}")
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
  
  defp handle_deal(%{deals: deals} = data, d) do 
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
end 