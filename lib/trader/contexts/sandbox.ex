defmodule Trader.Contexts.Sandbox do
  alias TinkoffInvest.Sandbox
  alias Trader.Utils
  require Logger

  def register(opts) do
    {Sandbox, :register_account, 0}
    |> Utils.fun_capture()
    |> Trader.UserRequest.send(opts)
  end

  def remove(opts) do
    {Sandbox, :remove_account, 0}
    |> Utils.fun_capture()
    |> Trader.UserRequest.send(opts)
  end

  def clear_positions(opts) do
    {Sandbox, :clear_positions, 0}
    |> Utils.fun_capture()
    |> Trader.UserRequest.send(opts)
  end

  def set_currency_balance(currency, balance, opts) do
    fn -> Sandbox.set_currency_balance(currency, balance) end
    |> Trader.UserRequest.send(opts)
    |> TinkoffInvest.payload()
  end

  def set_position_balance(figi, balance, opts) do
    fn -> Sandbox.set_position_balance(figi, balance) end
    |> Trader.UserRequest.send(opts)
    |> TinkoffInvest.payload()
  end
end
