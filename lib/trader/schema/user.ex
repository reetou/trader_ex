defmodule Trader.Schema.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Trader.Repo
  alias Trader.Schema.UserInstrument

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field(:telegram_id, :string)
    field(:telegram_username, :string)
    field(:token_hash, :string)
    field(:mode, :string, default: "sandbox")
    field(:broker_account_id, :string)

    field(:token, :string, virtual: true)

    has_many(:instruments, UserInstrument)

    timestamps()
  end

  def changeset(module, attrs) do
    module
    |> cast(
      attrs,
      [
        :telegram_id,
        :token_hash,
        :mode,
        :broker_account_id,
        :telegram_username
      ]
    )
    |> validate()
  end

  def update_changeset(module, attrs) do
    module
    |> cast(
      attrs,
      [
        :token_hash,
        :mode,
        :broker_account_id,
        :telegram_username
      ]
    )
    |> validate()
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert!()
  end

  def update(user, attrs) do
    user
    |> update_changeset(attrs)
    |> Repo.update!()
  end

  def get(id) do
    __MODULE__
    |> Repo.get!(id)
    |> with_token()
  end

  def by_telegram_id(id) do
    __MODULE__
    |> Repo.get_by(telegram_id: id)
    |> with_token()
  end

  def with_token(nil), do: nil

  def with_token(%__MODULE__{token_hash: nil} = user), do: user

  def with_token(%__MODULE__{token_hash: _} = user) do
    %__MODULE__{user | token: "sometoken"}
  end

  def with_instruments(nil), do: nil

  def with_instruments(%__MODULE__{} = module) do
    module
    |> Repo.preload([instruments: :instrument])
  end

  def validate(changeset) do
    changeset
    |> validate_required([:telegram_id, :mode])
    |> unique_constraint(:telegram_id)
    |> unique_constraint(:token_hash)
  end
end
