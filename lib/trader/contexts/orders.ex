defmodule Trader.Contexts.Orders do
  alias TinkoffInvest.Orders
  alias Trader.Utils
  alias Trader.Contexts.Instruments
  alias Trader.Contexts.User
  alias Trader.Schema.OrderHistory
  require Logger

  def active_orders(opts) do
    {Orders, :active_orders, 0}
    |> Utils.fun_capture()
    |> Trader.UserRequest.send(opts)
    |> TinkoffInvest.payload()
  end

  def create_limit_order(figi, lots, op, price, opts) do
    fn -> Orders.create_limit_order(figi, lots, op, price) end
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

  def buy_market(%{id: user_id, broker_account_id: account_id} = user, ticker, lots \\ 1) do
    with opts <- User.opts(user),
         {:ok, _} <- User.add_instrument(user, ticker),
         %{figi: figi} = instrument <- Instruments.by_ticker(ticker),
         %{payload: order, status_code: 200} <- create_market_order(figi, lots, :buy, opts),
         order_history_data <- build_order_history(order, instrument, %{broker_account_id: account_id, operation_type: "buy", user_id: user_id}),
         %{} <- write_order_history(order_history_data) do
      {:ok, order}
    else
      %{status_code: _} = r -> {:error, r}
      nil -> {:error, :no_instrument}
      {:error, :no_instrument} = e -> e
    end
  end

  def sell_market(%{id: user_id, broker_account_id: account_id} = user, ticker, lots \\ 1) do
    with opts <- User.opts(user),
         {:ok, _} <- User.add_instrument(user, ticker),
         %{figi: figi} = instrument <- Instruments.by_ticker(ticker),
         %{payload: order, status_code: 200} <- create_market_order(figi, lots, :sell, opts),
         order_history_data <- build_order_history(order, instrument, %{broker_account_id: account_id, operation_type: "sell", user_id: user_id}),
         %{} <- write_order_history(order_history_data) do
      {:ok, order}
    else
      %{status_code: _} = r -> {:error, r}
      nil -> {:error, :no_instrument}
      {:error, :no_instrument} = e -> e
    end
  end

  defp build_order_history(order, instrument, extra) do
    order
    |> Map.from_struct()
    |> Map.merge(Map.from_struct(instrument))
    |> Map.merge(extra)
  end

  def order_history(%{id: user_id}, ticker) do 
    OrderHistory.by_user_id(user_id, ticker)
  end
end
