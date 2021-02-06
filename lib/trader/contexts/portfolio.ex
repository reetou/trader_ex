defmodule Trader.Contexts.Portfolio do
  alias TinkoffInvest.Portfolio
  alias Trader.Utils
  require Logger

  def currencies(opts) do
    {Portfolio, :currencies, 0}
    |> Utils.fun_capture()
    |> Trader.UserRequest.send(opts)
  end

  def positions(opts) do
    {Portfolio, :positions, 0}
    |> Utils.fun_capture()
    |> Trader.UserRequest.send(opts)
  end

  def full(opts) do
    {Portfolio, :full, 0}
    |> Utils.fun_capture()
    |> Trader.UserRequest.send(opts)
  end
end
