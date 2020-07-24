defmodule FishPhoenix.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :claims, {:array, :string}
      add :room_id, references(:rooms, on_delete: :nothing)

      timestamps()
    end

    create index(:teams, [:room_id])
  end
end
