defmodule FishPhxLive.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :cards, {:array, :string}
    field :move, :string
    field :name, :string
    field :turn, :string

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:name, :cards, :move, :turn])
    |> validate_required([:name, :cards, :move, :turn])
  end
end
