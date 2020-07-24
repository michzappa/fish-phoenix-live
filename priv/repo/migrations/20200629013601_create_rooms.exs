defmodule FishPhoenix.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string
      add :cards, {:array, :string}
      add :move, :string
      add :turn, :string

      timestamps()
    end
  end
end
