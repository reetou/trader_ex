defmodule Trader.Schema.OrderHistory do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Trader.Repo
  alias Trader.Schema.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "order_history" do
    field(:name, :string)
    field(:broker_account_id, :string)
    field(:ticker, :string)
    field(:figi, :string)
    field(:operation_type, :string)
    field(:requested_lots, :integer)
    field(:executed_lots, :integer)
    field(:o, :float)
    field(:c, :float)
    field(:h, :float)
    field(:l, :float)
    field(:order_id, :string)
    
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(module, attrs) do
    module
    |> cast(
      attrs,
      [
        :order_id,
        :user_id,
        :name,
        :broker_account_id,
        :ticker,
        :figi,
        :operation_type,
        :requested_lots,
        :executed_lots,
        :o,
        :c,
        :h,
        :l
      ]
    )
    |> validate()
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert!()
  end

  def by(opts) do
    __MODULE__
    |> Repo.get_by(opts)
  end

  def validate(changeset) do
    changeset
    |> validate_required([:o, :c, :h, :l, :order_id, :user_id, :name, :broker_account_id, :ticker, :figi, :operation_type, :executed_lots, :requested_lots])
    |> validate_inclusion(:operation_type, ["buy", "sell"])
  end
end
