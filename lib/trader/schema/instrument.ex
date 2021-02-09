defmodule Trader.Schema.Instrument do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Trader.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "instruments" do
    field(:name, :string)
    field(:ticker, :string)
    field(:figi, :string)
    field(:o, :float)
    field(:c, :float)
    field(:h, :float)
    field(:l, :float)
    field(:currency, :string)
    field(:last_price_update, :naive_datetime)

    timestamps()
  end

  def changeset(module, attrs) do
    module
    |> cast(
      attrs,
      [
        :currency,
        :name,
        :ticker,
        :o,
        :c,
        :l,
        :h,
        :last_price_update,
        :figi,
      ]
    )
    |> validate()
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert!(on_conflict: :nothing)
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
    |> validate_required([:name, :ticker, :figi])
  end

  def by_tickers([]), do: []

  def by_tickers(tickers) when is_list(tickers) do
    Instrument
    |> where([i], i.ticker in ^tickers)
    |> Repo.all()
  end
end
