defmodule Trader.Contexts.Orders do
  alias TinkoffInvest.Orders
  alias Trader.Utils
  alias Trader.Contexts.Instruments
  alias Trader.Contexts.Portfolio
  alias Trader.Contexts.User
  alias Trader.Schema.OrderHistory
  require Logger

  def active_orders(opts) do
    {Orders, :active_orders, 0}
    |> Utils.fun_capture()
    |> Trader.UserRequest.send(opts)
    |> TinkoffInvest.payload()
  end

  def create_limit_order(figi, lots, op, opts) do
    fn -> Orders.create_limit_order(figi) end
    |> Trader.UserRequest.send(opts)
  end

  def create_market_order(figi, lots, op, opts) do
    fn -> Orders.create_market_order(figi, lots, op) end
    |> Trader.UserRequest.send(opts)
  end

  def cancel_order(id, opts) do
    fn -> Orders.cancel_order(id) end
    |> Trader.UserRequest.send(opts)
  end

  def write_order_history(data) do
    OrderHistory.create(data)
  end

  def buy(%{id: user_id, broker_account_id: account_id} = user, ticker, lots \\ 5) do
    with opts <- User.opts(user),
         %{figi: figi, name: name} <- Instruments.by_ticker(ticker),
         {:ok, _} <- User.add_instrument(user, ticker),
         %{payload: %{order_id: order_id} = order, status_code: 200} = r <- create_market_order(figi, lots, :buy, opts),
         order_history_data <- Map.merge(Map.from_struct(order), %{ticker: ticker, figi: figi, name: name, broker_account_id: account_id, operation_type: "buy", user_id: user_id}),
         %{} <- write_order_history(order_history_data) do
      {:ok, order}
    else
      %{status_code: _} = r -> {:error, r}
      nil -> {:error, :no_instrument}
      {:error, :no_instrument} = e -> e
    end
  end
end
