defmodule Trader.Contexts.Cache do
  alias TinkoffInvest.Model.Api.Error
  require Logger

  def set(key, value, ttl \\ 60000) do
    Cachex.put(:api_cache, key, value, ttl)
  end

  def get(key) do
    Cachex.get!(:api_cache, key)
  end

  def maybe_from_cache(cache_key, fun) do
    case get(cache_key) do
      nil ->
        fun.()
        |> TinkoffInvest.payload()
        |> handle_response(cache_key)

      result ->
        result
    end
  end

  defp handle_response(%Error{} = error, _) do
    Logger.error("Error at #{__MODULE__}: #{inspect(error)}")
    error
  end

  defp handle_response(payload, cache_key) do
    set(cache_key, payload)

    payload
    |> IO.inspect(label: "Market payload")
  end
end
