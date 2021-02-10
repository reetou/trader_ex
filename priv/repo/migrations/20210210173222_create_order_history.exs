defmodule Trader.Repo.Migrations.CreateOrderHistory do
  use Ecto.Migration

  def change do
    create table(:order_history, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :ticker, :string, null: false
      add :figi, :string, null: false
      add :broker_account_id, :string, null: false
      add :operation_type, :string, null: false
      add :requested_lots, :integer, null: false
      add :executed_lots, :integer, null: false
      add :price, :float
      add :order_id, :text, null: false

      add :user_id, references(:users, [type: :binary_id, on_delete: :delete_all]), null: false

      timestamps()
    end

    create index(:order_history, [:broker_account_id])
    create unique_index(:order_history, [:order_id])
  end
end
