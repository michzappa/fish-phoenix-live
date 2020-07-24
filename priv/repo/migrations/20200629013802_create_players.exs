defmodule FishPhoenix.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :name, :string
      add :hand, {:array, :string}
      add :team_id, references(:teams, on_delete: :nothing)
      add :room_id, references(:rooms, on_delete: :nothing)

      timestamps()
    end

    create index(:players, [:team_id, :room_id])
  end
end
