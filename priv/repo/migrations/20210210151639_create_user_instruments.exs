defmodule Trader.Repo.Migrations.CreateUserInstruments do
  use Ecto.Migration

  def change do
    create table(:user_instruments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :ticker, :string, null: false
      add :figi, :string, null: false
      add :broker_account_id, :string, null: false
      add :buy_price, :float
      add :sell_price, :float

      add :user_id, references(:users, [type: :binary_id, on_delete: :delete_all]), null: false
      add :instrument_id, references(:instruments, [type: :binary_id]), null: false

      timestamps()
    end

    create unique_index(:user_instruments, [:ticker, :figi])
    create index(:user_instruments, [:ticker])
    create index(:user_instruments, [:figi])
    create index(:user_instruments, [:user_id, :broker_account_id])
  end
end
