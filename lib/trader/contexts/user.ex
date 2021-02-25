defmodule Trader.Contexts.User do
  alias Trader.Schema.User
  alias Trader.Utils
  alias Trader.Contexts.Market
  alias Trader.Contexts.Orders
  alias Trader.Contexts.Sandbox
  alias Trader.Contexts.Instruments
  alias TinkoffInvest.Model.Api
  alias Trader.Schema
  require Logger

  def by_telegram(id), do: User.by_telegram_id("#{id}")

  def by_id(id), do: User.get(id)

  def token(%User{token_hash: nil}), do: nil

  def token(%User{token_hash: token}), do: token

  def account_id(%User{broker_account_id: account_id}), do: account_id

  def account(accs, account_id) do 
    accs
    |> Enum.find(fn %{broker_account_id: acc_id} -> acc_id == account_id end)
    |> case do 
      nil -> {:error, :no_account}
      %{} = acc -> {:ok, acc}
    end
  end

  def opts(%User{mode: mode} = user) do
    [
      mode: mode,
      account_id: account_id(user),
      token: token(user)
    ]
  end

  def create_broker_account(%User{mode: "sandbox"} = user) do
    user
    |> opts()
    |> Sandbox.register()
    |> case do
      %Api.Response{payload: %Api.Error{}} = r -> 
        {:error, r}
      %Api.Response{payload: _, status_code: 200} = r -> 
        {:ok, r}
    end
  end

  def create_broker_account(%User{mode: "production"}) do
    {:error, :wrong_mode}
  end

  def all_accounts(opts) do
    {TinkoffInvest.User, :accounts, 0}
    |> Utils.fun_capture()
    |> Trader.UserRequest.send(opts)
  end

  def add_instrument(%User{broker_account_id: broker_account_id, id: id}, ticker) do
    case Instruments.by_ticker(ticker) do 
      nil -> {:error, :no_instrument}
      %Schema.Instrument{figi: figi, ticker: ticker, name: name, id: instrument_id} -> 
        %Schema.UserInstrument{} = result = Schema.UserInstrument.create(%{
          ticker: ticker,
          figi: figi,
          broker_account_id: broker_account_id,
          user_id: id,
          instrument_id: instrument_id,
          name: name,
        })
        Instruments.fetch_watching_stocks_prices()
        {:ok, result}
    end
  end

  def get_instruments(%User{} = user) do
    user
    |> User.with_instruments()
  end

  def get_purchased(%User{broker_account_id: broker_account_id, mode: mode} = user) do 
    user
    |> opts()
    |> Keyword.put(:token, token(user))
    |> Keyword.put(:mode, mode)
    |> Orders.active_orders()
  end

  def maybe_update_telegram_username(telegram_id, username) do
    Logger.debug("Maybe update telegram username")
    telegram_id
    |> by_telegram()
    |> case do
      nil -> :ignore
      user ->
        User.update(user, %{telegram_username: username})
    end
  end

  def create_from_telegram(%{telegram_id: telegram_id, telegram_username: telegram_username}) do
    case by_telegram(telegram_id) do
      nil -> 
        User.create(%{telegram_id: "#{telegram_id}", telegram_username: telegram_username})
      _ -> {:error, :already_registered}  
    end
  end

  def delete(%{telegram_id: telegram_id}) do
    telegram_id
    |> by_telegram()
    |> User.delete()
  end

  def verify_credentials(%User{} = user, new_token) do
    user
    |> opts()
    |> Keyword.put(:token, new_token)
    |> all_accounts()
    |> case do
      %Api.Response{payload: %Api.Error{}} -> 
        :error
      %Api.Response{payload: accs, status_code: 200} -> 
        {:ok, accs}
    end
  end

  def verify_account(%User{broker_account_id: broker_account_id} = user) do
    user
    |> opts()
    |> all_accounts()
    |> case do
      %Api.Response{payload: %Api.Error{}} -> 
        :error
      %Api.Response{payload: accs, status_code: 200} -> 
        account(accs, broker_account_id)
    end
  end

  def write_credentials(%User{} = user, new_token) do
    case verify_credentials(user, new_token) do
      {:ok, accs} ->
        %User{} = user = User.update(user, %{token_hash: new_token})
        update_user_account(user, accs)
      :error -> 
        {:error, :bad_credentials}
    end
  end

  def update_user_account(user, accs) do
    case get_or_create_account(user, accs) do
      {:error, _} = e -> e
      {:ok, %{broker_account_id: acc_id}} -> 
        %User{} = user = User.update(user, %{broker_account_id: acc_id})
        {:ok, user}
    end
  end

  def algos(%{telegram_id: telegram_id}) do 
    telegram_id
    |> by_telegram()
    |> User.with_algos()
    |> Map.fetch!(:algos)
  end

  def active_algos(user) do 
    Schema.UserAlgo.all_active_for_user(user.id)
  end

  def add_algo(%{telegram_id: telegram_id, ticker: ticker, algo: algo}) when algo in ["buy_within"] do 
    %{id: user_id} = user = by_telegram(telegram_id)
    {:ok, _} = add_instrument(user, ticker)
    %{} = Schema.UserAlgo.create(%{user_id: user_id, ticker: ticker, balance_limit: 1000, algo: algo})
    :ok
  end

  def remove_algo(%{telegram_id: telegram_id, ticker: ticker, algo: algo}) when algo in ["buy_within"] do 
    %{id: user_id} = by_telegram(telegram_id)
    Schema.UserAlgo.delete(user_id, ticker, algo)
    :ok
  end

  def get_or_create_account(%User{} = user, accs \\ []) do
    with nil <- List.first(accs),
         {:ok, _} <- create_broker_account(user) do
      user
      |> opts()
      |> all_accounts()
      |> case do
        %Api.Response{payload: %Api.Error{}} = r -> 
          Logger.error("Error at fetch accounts: #{inspect r}")
          {:error, :api_error}
        %Api.Response{payload: accs, status_code: 200} = r -> 
          get_or_create_account(user, accs)
      end    
    else
      {:error, %Api.Response{} = r} ->
        Logger.error("Error at create account: #{inspect r}")
        {:error, :api_error}
      {:error, :wrong_mode} = e -> e
      %{} = acc -> {:ok, acc}  
    end
  end

  def check_credentials(%User{token_hash: nil}) do
    {:error, :no_credentials}
  end

  def check_credentials(%User{token_hash: token_hash}) do
    :ok
  end

  def with_valid_account(%{telegram_id: telegram_id}, module) when is_atom(module) do
    with true <- check?(module, :account),
         %User{} = user <- by_telegram(telegram_id),
         {:ok, account} <- verify_account(user) do
      :ok
    else
      false -> :ok  
      nil -> {:error, :not_registered}
      {:error, _} = e -> e
    end
  end

  def with_registered(%{telegram_id: telegram_id}, module) when is_atom(module) do
    with true <- check?(module, :register),
         %User{} <- by_telegram(telegram_id) do
      :ok
    else
      false -> :ok  
      nil -> {:error, :not_registered}
    end
  end

  def with_credentials(%{telegram_id: telegram_id}, module) when is_atom(module) do
    with true <- check?(module, :credentials),
         %User{} = user <- by_telegram(telegram_id),
         :ok <- check_credentials(user) do
      :ok
    else
      false -> :ok  
      {:error, reason} = x -> x
    end
  end

  defp check?(module, check_name) when is_atom(check_name) do 
    check_name in module.checks()
  end
end
