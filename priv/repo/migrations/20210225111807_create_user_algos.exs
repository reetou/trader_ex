defmodule Trader.Repo.Migrations.CreateUserAlgos do
  use Ecto.Migration

  def change do
    create table(:user_algos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ticker, :string, null: false
      add :algo, :string, null: false
      add :active, :boolean, null: false
      add :balance_limit, :float, null: false

      add :user_id, references(:users, [type: :binary_id, on_delete: :delete_all]), null: false

      timestamps()
    end

    create unique_index(:user_algos, [:ticker, :user_id, :algo])
  end
end
