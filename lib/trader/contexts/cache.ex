defmodule Trader.Contexts.Cache do
  alias TinkoffInvest.Model.Api.Error
  require Logger

  def set(key, value, opts \\ []) do
    Cachex.put(:api_cache, key, value, opts)
  end

  def get(key) do
    Cachex.get!(:api_cache, key)
  end

  def maybe_from_cache(cache_key, fun, ttl \\ 60000) do
    case get(cache_key) do
      nil ->
        fun.()
        |> TinkoffInvest.payload()
        |> handle_response(cache_key, ttl)

      result ->
        Logger.debug("Loaded from cache by key #{cache_key}")
        result
    end
  end

  defp handle_response(%Error{} = error, _) do
    Logger.error("Error at #{__MODULE__}: #{inspect(error)}")
    error
  end

  defp handle_response(payload, cache_key, ttl) do
    set(cache_key, payload, ttl: ttl)

    payload
  end
end
