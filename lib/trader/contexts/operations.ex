defmodule Trader.Contexts.Operations do
  alias TinkoffInvest.Operations
  require Logger

  def history(from, to, figi \\ nil, opts) do
    fn -> Operations.history(from, to, figi) end
    |> Trader.UserRequest.send(opts)
  end
end
