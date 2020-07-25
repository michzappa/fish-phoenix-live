defmodule FishPhxLive.Teams do
  import Ecto.Query, warn: false
  alias FishPhxLive.Repo

  alias FishPhxLive.Teams.Team
  alias FishPhxLive.Players
  alias FishPhxLive.Rooms
  alias FishPhxLive.Cards

  # sends all the team changesets
  def list_teams do
    Repo.all(Team)
  end

  # sends a team changeset specified by the given id
  def get_team!(id) do
    Repo.get!(Team, id)
  end

  # given a team id, returns the id of their opponent in their room
  def get_opponent_team_id(team_id) do
    case rem(team_id, 2) do
      0 -> team_id - 1
      1 -> team_id + 1
    end
  end

  # second parameter is a map of %{id=>card}
  def make_claim(team_id, player_card_map) do
    cards = Map.values(player_card_map)
    cards = List.flatten(cards)

    room_id = get_team!(team_id).room_id

    opponent_team_id =
      if rem(team_id, 2) == 0 do
        team_id - 1
      else
        team_id + 1
      end

    case is_valid_claim(cards) do
      false ->
        :invalid

      true ->
        case all_players_have_their_specified_cards(player_card_map) do
          false ->
            wrong_claim(
              room_id,
              team_id,
              opponent_team_id,
              cards,
              Cards.cards_are_in_play(room_id, cards)
            )

          true ->
            add_claim(room_id, team_id, player_card_map, cards)
        end
    end
  end

  # determines if the given claim has 6 cards and if they are all in the same halfsuit
  def is_valid_claim(cards) do
    # and Cards.all_in_same_halfsuit(cards)
    Kernel.length(cards) == 6
  end

  # determines if every player, card pair in the given map is correct
  def all_players_have_their_specified_cards(player_card_map) do
    Enum.reduce(player_card_map, true, fn {id, cards}, acc ->
      acc && Players.does_player_have_all_cards(id, cards)
    end)
  end

  # removes the cards from the players in the map and adds the cards to this team as a claim
  def add_claim(room_id, team_id, player_card_map, cards) do
    Enum.map(player_card_map, fn {id, cards} -> take_all_cards_from_player(id, cards) end)

    add_claim_to_team(room_id, team_id, cards)
  end

  # adds the given claim to the given team
  def add_claim_to_team(room_id, team_id, cards) do
    team = get_team!(team_id)
    new_claims = [Enum.join(cards, " ") | team.claims]

    team_players = Players.get_players_on_team(team_id)
    team_players = Enum.map(team_players, fn player -> Players.get_player!(player.id).name end)

    Rooms.update_move(
      room_id,
      "The claim [#{Enum.join(cards, ", ")}] was given to team #{Enum.join(team_players, ", ")}"
    )

    Team.changeset(team, %{
      claims: new_claims,
      room_id: team.room_id
    })
    |> Repo.update()
  end

  def take_all_cards_from_player(id, cards) do
    Enum.map(cards, fn card -> Players.take_card_from_player(id, card) end)
  end

  # removes the given cards from circulation and adds them to the claims of the opponent team
  def wrong_claim(room_id, team_id, opponent_team_id, cards, _in_play = true) do
    team_players = Players.get_players_on_team(team_id)
    opponent_players = Players.get_players_on_team(opponent_team_id)

    # removing all the cards from every player in the game, if they exist in their hand
    Enum.each(team_players, &take_all_cards_from_player(&1.id, cards))
    Enum.each(opponent_players, &take_all_cards_from_player(&1.id, cards))

    add_claim_to_team(room_id, opponent_team_id, cards)
  end

  def wrong_claim(_, _, _, _, _in_play = false) do
    :not_in_play
  end
end
