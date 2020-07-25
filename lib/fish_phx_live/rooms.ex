defmodule FishPhxLive.Rooms do
  require Logger

  import Ecto.Query, warn: false
  alias FishPhxLive.Repo

  alias FishPhxLive.Rooms.Room
  alias FishPhxLive.Teams.Team
  alias FishPhxLive.Players.Player
  alias FishPhxLive.Players
  alias FishPhxLive.Cards

  def list_rooms do
    Repo.all(Room)
  end

  def get_room!(id) do
    Repo.get!(Room, id)
  end

  # deletes the specified room and its associated teams and players
  def delete_room(name) do
    room = get_room_by_name!(name)
    id = room.id
    {team1ID, team2ID} = get_team_ids(id)

    Repo.delete_all(
      from player in Player, where: player.team_id == ^team1ID or player.team_id == ^team2ID
    )

    Repo.delete_all(from team in Team, where: team.room_id == ^id)
    Repo.delete_all(from room in Room, where: room.id == ^id)
  end

  def get_room_by_name!(name) do
    Repo.get_by!(Room, name: name)
  end

  # adds a room and its two teams
  def create_room(name) do
    case does_room_name_already_exist(name) do
      true -> {:error, "Room #{name} already exists"}
      false -> insert_room(name)
    end
  end

  # inserts the room, having already checked for no duplicate name
  def insert_room(name) do
    {:ok, room} =
      %Room{}
      |> Room.changeset(%{
        name: name,
        cards: Cards.get_shuffled_deck(),
        move: "No moves have occured",
        turn: "No one's turn"
      })
      |> Repo.insert()

    create_associated_teams(room.id)
    room
  end

  def create_associated_teams(room_id) do
    Repo.insert!(Team.changeset(%Team{}, %{room_id: room_id, claims: []}))
    Repo.insert!(Team.changeset(%Team{}, %{room_id: room_id, claims: []}))
  end

  def does_room_name_already_exist(name) do
    room_names = Repo.all(from room in Room, select: room.name)
    Enum.member?(room_names, name)
  end

  def add_player_to_room(room_name, player_name, _checked_duplicate = false)
      when is_bitstring(room_name) do
    room_id = get_room_by_name!(room_name).id
    add_player_to_room(room_name, room_id, player_name, false)
  end

  # adds player with given name to the given room id
  def add_player_to_room(room_name, room_id, player_name, _checked_duplicate = false) do
    case does_player_name_exist_in_room(room_id, player_name) do
      true -> {:error, "Player #{player_name} already is in room #{room_name}"}
      false -> add_player_to_room(room_name, room_id, player_name, true)
    end
  end

  def add_player_to_room(_room_name, room_id, player_name, _checked_duplicate = true) do
    {team1ID, team2ID} = get_team_ids(room_id)

    case :rand.uniform(2) do
      1 -> add_to_team(player_name, team1ID, team2ID, room_id)
      2 -> add_to_team(player_name, team2ID, team1ID, room_id)
    end
  end

  defp does_player_name_exist_in_room(room_id, player_name) do
    {team1ID, team2ID} = get_team_ids(room_id)

    names_in_room =
      Repo.all(
        from player in Player,
          where: player.team_id == ^team1ID or player.team_id == ^team2ID,
          select: player.name
      )

    Enum.member?(names_in_room, player_name)
  end

  defp add_to_team(name, desired_team, other_team, room_id) do
    desired_team_size = Kernel.length(Players.get_players_on_team(desired_team))
    other_team_size = Kernel.length(Players.get_players_on_team(other_team))
    # Logger.info(desired_team_size)
    # Logger.info(other_team_size)

    cond do
      desired_team_size > 2 and other_team_size > 2 -> {:error, "Both teams are full"}
      desired_team_size < 3 -> Players.add_player_to_team(desired_team, name, room_id)
      true -> Players.add_player_to_team(other_team, name, room_id)
    end
  end

  # returns the two teams in this room, based off the insertion method of teams
  defp get_team_ids(id) do
    {2 * id - 1, 2 * id}
  end

  # returns the next hand in the room's deck and updates the remaining cards
  def get_next_hand_and_update_remaining_cards(id) do
    room = get_room!(id)
    {next_hand, remaining_cards} = Enum.split(room.cards, 9)

    Room.changeset(room, %{
      name: room.name,
      cards: remaining_cards,
      move: room.move,
      turn: room.turn
    })
    |> Repo.update()

    next_hand
  end

  def update_move(id, move) do
    room = get_room!(id)
    update_move_and_turn(id, move, room.turn)
  end

  def update_move_and_turn(id, move, turn) do
    room = get_room!(id)

    Room.changeset(room, %{
      name: room.name,
      cards: room.cards,
      move: move,
      turn: turn
    })
    |> Repo.update()
  end
end
