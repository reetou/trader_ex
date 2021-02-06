defmodule Trader.Contexts.Orders do
  alias TinkoffInvest.Orders
  alias Trader.Utils
  require Logger

  def active_orders(opts) do
    {Orders, :active_orders, 0}
    |> Utils.fun_capture()
    |> Trader.UserRequest.send(opts)
  end

  def create_limit_order(figi, opts) do
    fn -> Orders.create_limit_order(figi) end
    |> Trader.UserRequest.send(opts)
  end

  def create_market_order(figi, opts) do
    fn -> Orders.create_market_order(figi) end
    |> Trader.UserRequest.send(opts)
  end

  def cancel_order(id, opts) do
    fn -> Orders.cancel_order(id) end
    |> Trader.UserRequest.send(opts)
  end
end
