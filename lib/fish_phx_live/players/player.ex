defmodule FishPhxLive.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "players" do
    field :hand, {:array, :string}
    field :name, :string
    field :team_id, :id
    field :room_id, :id

    timestamps()
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :hand, :team_id, :room_id])
    |> validate_required([:name, :hand, :team_id, :room_id])
  end
end
