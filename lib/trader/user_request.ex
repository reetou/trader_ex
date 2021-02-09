defmodule Trader.UserRequest do
  use GenServer

  def init(_) do
    {:ok, []}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def handle_call({:send, fun, opts}, _from, state) do
    result = 
      opts
      |> Keyword.take([:token, :account_id, :mode])
      |> change_account_id()
      |> change_token()
      |> change_mode()
      |> execute(fun)
    {:reply, result, state}  
  end

  def send(fun, opts) do
    GenServer.call(__MODULE__, {:send, fun, opts})
  end

  defp change_account_id(opts) do
    :ok =
      opts
      |> Keyword.get(:account_id)
      |> TinkoffInvest.change_account_id()

    opts
  end

  defp change_token(opts) do
    :ok =
      opts
      |> Keyword.fetch!(:token)
      |> TinkoffInvest.change_token()

    opts
  end

  defp change_mode(opts) do
    :ok =
      opts
      |> Keyword.fetch!(:mode)
      |> String.to_existing_atom()
      |> TinkoffInvest.set_mode()

    opts
  end

  defp execute(_, fun) do
    fun.()
  end
end
