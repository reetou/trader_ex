defmodule Trader.Repo.Migrations.CreateInstruments do
  use Ecto.Migration

  def change do
    create table(:instruments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :ticker, :string, null: false
      add :figi, :string, null: false
      add :currency, :string, null: false
      add :o, :float
      add :c, :float
      add :h, :float
      add :l, :float
      add :last_price_update, :naive_datetime

      timestamps()
    end

    create unique_index(:instruments, [:ticker])
    create unique_index(:instruments, [:figi])
  end
end
