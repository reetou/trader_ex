defmodule Trader.Contexts.DecisionExecutor do 
  alias Trader.Contexts.Orders
  require Logger

  def execute({:buy, lots}, user, ticker) do 
    Logger.info("Buy #{ticker} #{lots} for user #{user.id}")
    Orders.buy_market(user, ticker, lots)
  end

  def execute({:sell, lots}, user, ticker) do 
    Logger.info("Sell #{ticker} #{lots} for user #{user.id}")
    Orders.sell_market(user, ticker, lots)
  end

  def execute({:limit, _, _, _} = x, _, _) do 
    raise "Not implemented limit orders execution: #{inspect x}"
  end

  def execute(:ignore, _, ticker) do 
    Logger.debug("Ignore ticker #{ticker}")
    :ignore
  end
end