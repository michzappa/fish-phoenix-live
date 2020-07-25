defmodule FishPhxLive.Players do
  import Ecto.Query, warn: false
  alias FishPhxLive.Repo

  alias FishPhxLive.Players.Player
  alias FishPhxLive.Rooms
  alias FishPhxLive.Cards

  def list_players do
    Repo.all(Player)
  end

  def get_player!(id) do
    Repo.get!(Player, id)
  end

  # adds a player with the given name to the given team ID
  def add_player_to_team(team_id, name, room_id) do
    hand = Rooms.get_next_hand_and_update_remaining_cards(room_id)

    {:ok, player} =
      %Player{}
      |> Player.changeset(%{
        name: name,
        hand: Cards.sort_cards(hand),
        team_id: team_id,
        room_id: room_id
      })
      |> Repo.insert()

    Rooms.update_move_and_turn(room_id, "No moves have occurred", player.name)
    player
  end

  def get_players_in_room(room_id) do
    query =
      from player in Player,
        where: player.room_id == ^room_id,
        select: player

    Repo.all(query)
  end

  def get_players_on_team(team_id) do
    query =
      from player in Player,
        where: player.team_id == ^team_id,
        select: player

    Repo.all(query)
  end

  def check_if_asked_player_has_any_cards(asking_id, asked_id, card, room_id) do
    asked_player = get_player!(asked_id)

    cond do
      Kernel.length(asked_player.hand) == 0 -> {:error, "Asked player has no cards"}
      true -> ask_for_card(asking_id, asked_id, card, room_id)
    end
  end

  # checks if the asking player can ask for the specified card before proceding with the action of doing so
  def ask_for_card(asking_id, asked_id, card, room_id) do
    asking_player = get_player!(asking_id)

    room_current_turn = Rooms.get_room!(room_id).turn

    case Cards.can_ask_for_card(asking_player.hand, card) and
           asking_player.name == room_current_turn do
      false -> {:error, "#{asking_player.name} cannot ask for #{card}"}
      true -> ask_player_for_card(asking_id, asked_id, card, room_id)
    end
  end

  # asking player asking the asked player for the specified card, assuming it is a valid ask
  def ask_player_for_card(asking_id, asked_id, card, room_id) do
    asking_name = get_player!(asking_id).name
    asked_name = get_player!(asked_id).name

    case does_player_have_card(asked_id, card) do
      true ->
        exchange_card(asked_id, asking_id, card, room_id)

      false ->
        Rooms.update_move_and_turn(
          room_id,
          "#{asking_name} asked #{asked_name} for the #{card}, but they did not have it",
          asked_name
        )
    end
  end

  def exchange_card(from_player_id, to_player_id, card, room_id) do
    take_card_from_player(from_player_id, card)
    give_card_to_player(to_player_id, card)

    from_player_name = get_player!(from_player_id).name
    to_player_name = get_player!(to_player_id).name

    Rooms.update_move_and_turn(
      room_id,
      "#{to_player_name} asked #{from_player_name} for the #{card}, and #{to_player_name} received it",
      to_player_name
    )
  end

  def take_card_from_player(id, card) do
    player = get_player!(id)
    new_hand = Enum.filter(player.hand, fn card_in_hand -> card_in_hand != card end)

    Player.changeset(player, %{
      name: player.name,
      hand: Cards.sort_cards(new_hand),
      team_id: player.team_id
    })
    |> Repo.update()
  end

  def give_card_to_player(id, card) do
    player = get_player!(id)
    new_hand = [card | player.hand]

    Player.changeset(player, %{
      name: player.name,
      hand: Cards.sort_cards(new_hand),
      team_id: player.team_id
    })
    |> Repo.update()
  end

  def does_player_have_all_cards(id, cards) do
    Enum.reduce(cards, true, fn card, acc -> acc && does_player_have_card(id, card) end)
  end

  def does_player_have_card(id, card) do
    player = get_player!(id)

    Enum.member?(player.hand, card)
  end
end
