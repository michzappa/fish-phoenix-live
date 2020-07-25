defmodule FishPhxLive.Cards do
  alias FishPhxLive.Players

  @cardmap %{
    "2-H" => {0, 0},
    "3-H" => {0, 1},
    "4-H" => {0, 2},
    "5-H" => {0, 3},
    "6-H" => {0, 4},
    "7-H" => {0, 5},
    "9-H" => {1, 0},
    "10-H" => {1, 1},
    "J-H" => {1, 2},
    "Q-H" => {1, 3},
    "K-H" => {1, 4},
    "A-H" => {1, 5},
    "2-D" => {2, 0},
    "3-D" => {2, 1},
    "4-D" => {2, 2},
    "5-D" => {2, 3},
    "6-D" => {2, 4},
    "7-D" => {2, 5},
    "9-D" => {3, 0},
    "10-D" => {3, 1},
    "J-D" => {3, 2},
    "Q-D" => {3, 3},
    "K-D" => {3, 4},
    "A-D" => {3, 5},
    "2-S" => {4, 0},
    "3-S" => {4, 1},
    "4-S" => {4, 2},
    "5-S" => {4, 3},
    "6-S" => {4, 4},
    "7-S" => {4, 5},
    "9-S" => {5, 0},
    "10-S" => {5, 1},
    "J-S" => {5, 2},
    "Q-S" => {5, 3},
    "K-S" => {5, 4},
    "A-S" => {5, 5},
    "2-C" => {6, 0},
    "3-C" => {6, 1},
    "4-C" => {6, 2},
    "5-C" => {6, 3},
    "6-C" => {6, 4},
    "7-C" => {6, 5},
    "9-C" => {7, 0},
    "10-C" => {7, 1},
    "J-C" => {7, 2},
    "Q-C" => {7, 3},
    "K-C" => {7, 4},
    "A-C" => {7, 5},
    "8-H" => {8, 0},
    "8-D" => {8, 1},
    "8-S" => {8, 2},
    "8-C" => {8, 3},
    "B-J" => {8, 4},
    "R-J" => {8, 5}
  }

  # sorts cards by halfsuit and order
  def sort_cards(cards) do
    Enum.sort(cards, fn card1, card2 -> order_two_cards(card1, card2) end)
  end

  def order_two_cards(card1, card2) do
    {suit1, order1} = Map.get(@cardmap, card1)
    {suit2, order2} = Map.get(@cardmap, card2)

    cond do
      suit1 < suit2 -> true
      suit1 > suit2 -> false
      true -> order1 < order2
    end
  end

  # return the cards that can be asked by a player with the given hand
  def player_can_ask_for_cards(hand) do
    halfsuits_in_hand(hand)
    # getting all the cards in all the halfsuits of each card in the hand
    |> Enum.flat_map(&get_cards_in_halfsuit_from_map/1)
    |> Enum.map(fn {card, _id} -> card end)
    # removing cards in the hand
    |> Enum.filter(fn card -> not Enum.member?(hand, card) end)
    |> sort_cards()
  end

  # returns all the cards in the specified halfsuitid
  def get_cards_in_halfsuit(halfsuit_id) do
    get_cards_in_halfsuit_from_map(halfsuit_id)
    |> Enum.map(fn {card, _id} -> card end)
    |> sort_cards()
  end

  def get_cards_in_halfsuit_from_map(halfsuit_id) do
    Enum.filter(@cardmap, fn {_card, {id, _order}} -> id == halfsuit_id end)
  end

  # returns a list of the halfsuit ids in the given hand
  def halfsuits_in_hand(hand) do
    Enum.map(hand, fn card -> elem(Map.get(@cardmap, card), 0) end)
    |> Enum.uniq()
  end

  # returns if all the cards currently exist in player's hands in the current room
  def cards_are_in_play(room_id, cards) do
    List.foldr(cards, true, fn card, acc ->
      acc && is_card_in_play(room_id, card)
    end)
  end

  def is_card_in_play(room_id, card) do
    players_in_room = Players.get_players_in_room(room_id)
    hands_in_room = Enum.map(players_in_room, fn id -> Players.get_player!(id).hand end)
    IO.inspect(hands_in_room)

    List.foldr(hands_in_room, false, fn hand, acc ->
      IO.inspect(hand)
      acc || Enum.member?(hand, card)
    end)
  end

  # returns if the given hand has a card in the same halfsuit as the given card that is not the given card
  def can_ask_for_card(hand, card) do
    case Enum.member?(hand, card) do
      true ->
        false

      false ->
        has_same_halfsuit(hand, card)
    end
  end

  # determines if the given hand has a card in the same halfsuit as the given card
  def has_same_halfsuit(hand, card) do
    Enum.reduce(
      hand,
      false,
      fn card_in_hand, acc ->
        acc or in_same_halfsuit(card_in_hand, card)
      end
    )
  end

  # returns a boolean if the two given cards are mapped to the same halfsuit value in the module attribute map
  def in_same_halfsuit(card1, card2) do
    elem(Map.get(@cardmap, card1), 0) == elem(Map.get(@cardmap, card2), 0)
  end

  # returns whether all the given cards are in the same halfsuit
  def all_in_same_halfsuit([first_card | rest_of_hand]) do
    Enum.reduce(rest_of_hand, true, fn card, acc -> acc && in_same_halfsuit(first_card, card) end)
  end

  def get_shuffled_deck() do
    cards = Map.keys(@cardmap)
    Enum.shuffle(cards)
  end
end
