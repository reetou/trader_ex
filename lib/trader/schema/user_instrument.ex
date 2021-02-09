defmodule Trader.Schema.UserInstrument do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Trader.Repo
  alias Trader.Schema.User
  alias Trader.Schema.Instrument

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_instruments" do
    field(:name, :string)
    field(:broker_account_id, :string)
    field(:ticker, :string)
    field(:figi, :string)
    field(:buy_price, :float)
    field(:sell_price, :float)

    belongs_to(:instrument, Instrument)
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(module, attrs) do
    module
    |> cast(
      attrs,
      [
        :instrument_id,
        :name,
        :user_id,
        :broker_account_id,
        :ticker,
        :figi,
        :buy_price,
        :sell_price
      ]
    )
    |> validate()
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert!()
  end

  def update(%__MODULE__{} = module, attrs) do
    module
    |> changeset(attrs)
    |> Repo.update!()
  end

  def by(opts) do
    __MODULE__
    |> Repo.get_by(opts)
  end

  def validate(changeset) do
    changeset
    |> validate_required([:name, :broker_account_id, :ticker, :figi])
  end

  def all_figi do
    __MODULE__
    |> select([i], [i.figi])
    |> distinct([:ticker])
    |> limit(2)
    |> Repo.all()
    |> List.flatten()
  end
end
