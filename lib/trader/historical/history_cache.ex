defmodule Trader.Historical.HistoryCache do 
  use GenServer
  alias TinkoffInvest.HistoricalData
  require Logger

  def init(_) do
    Logger.debug("Init #{__MODULE__}")
    {:ok, %{}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def handle_call({:load, figi, from, to, interval}, _from, state) do 
    from_key = date_key(from)
    to_key = date_key(to)
    key = {from_key, to_key, interval}
    candles =
      case from_cache(state, figi, key) do
        nil -> 
          Logger.debug("Going to api for key #{inspect key}")
          from_api(figi, from, to, interval)
        x -> 
          x
      end
    state =
      state
      |> maybe_init_state(figi)
      |> put_in([figi, key], candles)  
    {:reply, candles, state}
  end

  def load(figi, from, to, interval) do 
    GenServer.call(__MODULE__, {:load, figi, from, to, interval})
  end 

  defp maybe_init_state(state, figi) do 
    case Map.get(state, figi) do 
      nil -> Map.put(state, figi, %{})
      _ -> state
    end
  end
  
  defp from_api(figi, from, to, interval) do 
    HistoricalData.candles(figi, from, to, interval)
  end

  defp from_cache(state, figi, date_label) do 
    case Map.get(state, figi) do 
      nil -> nil
      date_map -> Map.get(date_map, date_label)
    end
  end

  defp date_key(date) do 
    date
    |> Timex.beginning_of_day()
    |> DateTime.to_iso8601()
  end
end 