defmodule Trader.Contexts.User do
  alias Trader.Schema.User
  alias Trader.Utils

  def by_telegram(id), do: User.by_telegram_id(id)

  def by_id(id), do: User.get(id)

  def token(%User{token_hash: nil}), do: nil

  def token(%User{token: token}), do: token

  def account_id(%User{broker_account_id: account_id}), do: account_id

  def all_accounts(opts) do
    {TinkoffInvest.User, :accounts, 0}
    |> Utils.fun_capture()
    |> Trader.UserRequest.send(opts)
  end
end
