defmodule Trader.Schema.UserAlgo do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Trader.Repo
  alias Trader.Schema.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "user_algos" do
    field(:algo, :string)
    field(:ticker, :string)
    field(:balance_limit, :float)
    field(:active, :boolean, default: false)

    belongs_to(:user, User)

    timestamps()
  end

  def changeset(module, attrs) do
    module
    |> cast(
      attrs,
      [
        :algo,
        :active,
        :user_id,
        :balance_limit,
        :ticker
      ]
    )
    |> validate()
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert!(
      on_conflict: :nothing,
      conflict_target: [:ticker, :user_id, :algo]
    )
  end

  def delete(user_id, ticker, algo) do
    by(user_id: user_id, ticker: ticker, algo: algo)
    |> case do 
      nil -> nil
      x -> Repo.delete!(x)
    end
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

  def by_user_id(id) do 
    __MODULE__
    |> where([i], i.user_id == ^id)
    |> Repo.all()
  end

  def validate(changeset) do
    changeset
    |> validate_required([:algo, :user_id, :ticker, :balance_limit])
  end

  def all_active_for_user(user_id) do 
    __MODULE__
    |> where([i], i.user_id == ^user_id and i.active == true)
    |> Repo.all()
  end

  def all_active do 
    __MODULE__
    |> where([i], i.active == true)
    |> Repo.all()
  end
end
