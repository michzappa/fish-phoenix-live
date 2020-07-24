defmodule FishPhxLive.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  schema "teams" do
    field :claims, {:array, :string}
    field :room_id, :id

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:claims, :room_id])
    |> validate_required([:claims, :room_id])
  end
end
