defmodule Trader.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :telegram_id, :text
      add :token_hash, :text
      add :broker_account_id, :string
      add :mode, :string, null: false
      add :telegram_username, :string

      timestamps()
    end

    create unique_index(:users, [:telegram_id])
    create unique_index(:users, [:token_hash])
  end
end
