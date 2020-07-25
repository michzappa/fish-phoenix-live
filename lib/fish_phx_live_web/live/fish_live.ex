defmodule FishPhxLiveWeb.FishLive do
  use FishPhxLiveWeb, :live_view

  alias FishPhxLive.Rooms
  alias FishPhxLive.Teams
  alias FishPhxLive.Players
  alias FishPhxLive.Cards
  alias Phoenix.PubSub

  import Phoenix.LiveView

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        room_to_be_created: "",
        room_to_be_deleted: "",
        room_to_be_joined: "",
        joining_player_name: "",
        all_rooms: Rooms.list_rooms(),
        # boolean for displaying values only relevant after the player has joined a game
        joined_game: false,
        room_name: "",
        player_name: "",
        room: %{},
        player: %{},
        cards_can_ask_for: [],
        team: %{},
        teammates: [],
        opponent_team: %{},
        opponents: [],
        asked_for_card: "",
        claim_name_id_map: %{
          "Low Hearts" => 0,
          "High Hearts" => 1,
          "Low Diamonds" => 2,
          "High Diamonds" => 3,
          "Low Spades" => 4,
          "High Spades" => 5,
          "Low Clubs" => 6,
          "High Clubs" => 7,
          "Eights and Jokers" => 8
        },
        selected_claim_halfsuit: 8
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
      <div class="App">
        <header class="App-header">
          <h1>Fish</h1>
          <h4>By: Michael Zappa</h4>
        <%= unless @joined_game do %>
          <form phx-submit="create/delete-room">
            <input type="text" name="room_to_be_created" value="<%= @room_to_be_created %>"
                  placeholder="Room to be Created"/>
            <input type="text" name="room_to_be_deleted" value="<%= @room_to_be_deleted %>"
                  placeholder="Room to be Deleted"/>
            <button type="submit">
              Submit
            </button>
          </form>
          <form phx-submit="join-room">
            <select id="room-select" name="room_name">
                <%= for room <- @all_rooms do %>
                  <option value="<%= room.name %>"><%= room.name %></option>
                <% end %>
              </select>
            <input type="text" name="player_name" value="<%= @joining_player_name %>"
                  placeholder="Player Name"/>
            <button type="submit">
              Join Room
            </button>
          </form>
        <% end %>
        </header>

        <%= if @joined_game do %>
          <div class="game-information">
            <div class="game-stat">
              <h1>Room Name: <%= @room_name %></h1>
            </div>
            <div class="game-stat">
              <h2>
                Teammates: <%= Enum.join(Enum.map(@teammates, fn teammate -> teammate.name end),", ") %>
                <br></br>
                Team Score: <%= Kernel.length(@team.claims) %>
              </h2>
            </div>
            <div class="game-stat">
              <h2>
                Opponents: <%= Enum.join(Enum.map(@opponents, fn opponent -> opponent.name end),", ") %>
                <br></br>
                Opponents Score: <%= Kernel.length(@opponent_team.claims) %>
              </h2>
            </div>
            <div class="game-stat">
              <h1> <%= @player_name %>'s Hand</h1>
              <p><%= Enum.join(@player.hand, ", ") %></p>
            </div>
            <div class="game-stat">
              <h1>Last Move: <%= @room.move %></h1>
            </div>
            <div class="game-stat">
              <h1>Current Turn: <%= @room.turn %></h1>
            </div>
          </div>
          <div>
            <div>
              <h1>Ask for Card</h1>
              <form phx-submit="ask-for-card">
                <select id="opponents-select" name="asked_player">
                  <%= for opponent <- @opponents do %>
                    <option value="<%= opponent.id %>"><%= opponent.name %></option>
                  <% end %>
                </select>
                <select id="card-select" name="card">
                  <%= for card <- @cards_can_ask_for do %>
                    <option value="<%= card %>"><%= card %></option>
                  <% end %>
                </select>
                <button type="submit">
                  Ask For Card
                </button>
              </form>
            </div>
            <div>
              <h1>Make Claim</h1>
              <form phx-submit="update-selected-halfsuit">
                <select id="choose halfsuit" name="halfsuit_id" >
                  <%= for {k, v} <- @claim_name_id_map do %>
                    <option value="<%= v %>"><%= k %></option>
                  <% end %>
                </select>
                <button type="submit">
                  Change halfsuit
                </button>
              </form>

            <form phx-submit="make-claim">
              <%= if is_nil(Enum.at(@teammates, 0)) do %>
                <%= "" %>
              <% else %>
                <label for="teammate1-cards">
                  <%= Enum.at(@teammates, 0).name %>
                </label>
                <%= multiple_select(:claim,
                String.to_atom(Integer.to_string(Enum.at(@teammates, 0).id)),
                Enum.map(Cards.get_cards_in_halfsuit(@selected_claim_halfsuit),
                fn card -> {String.to_atom(card), card} end)) %>
              <% end %>

              <%= if is_nil(Enum.at(@teammates, 1)) do %>
                  <%= "" %>
              <% else %>
                <label for="teammate2-cards">
                  <%= Enum.at(@teammates, 1).name %>
                </label>
                <%= multiple_select(:claim,
                String.to_atom(Integer.to_string(Enum.at(@teammates, 1).id)),
                Enum.map(Cards.get_cards_in_halfsuit(@selected_claim_halfsuit),
                fn card -> {String.to_atom(card), card} end)) %>
              <% end %>

              <%= if is_nil(Enum.at(@teammates, 2)) do %>
                  <%= "" %>
              <% else %>
                <label for="teammate3-cards">
                  <%= Enum.at(@teammates, 2).name %>
                </label>
                <%= multiple_select(:claim,
                String.to_atom(Integer.to_string(Enum.at(@teammates, 2).id)),
                Enum.map(Cards.get_cards_in_halfsuit(@selected_claim_halfsuit),
                fn card -> {String.to_atom(card), card} end)) %>
              <% end %>

              <button type="submit">
                Make Claim
              </button>
            </form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # make claim event
  def handle_event("make-claim", %{"claim" => player_card_map}, socket) do
    IO.inspect(player_card_map)
    IO.inspect(socket.assigns.team.id)
    case Teams.make_claim(socket.assigns.team.id, player_card_map) do
      :not_in_play ->
        socket = put_flash(socket, :error, "the specified cards are not all in play")
        {:noreply, socket}
      :invalid ->
        socket = put_flash(socket, :error, "invalid claim")
        {:noreply, socket}
      {:ok, _team} ->
        PubSub.broadcast!(:fish_pubsub, "room:#{socket.assigns.room_name}", "update")
        {:noreply, socket}
    end
  end

  def handle_event("make-claim", _, socket) do
    {:noreply, socket}
  end

  # update selected halfsuit for claim event
  def handle_event("update-selected-halfsuit", %{"halfsuit_id" => halfsuit_id}, socket) do
    IO.inspect(halfsuit_id)
    socket = assign(socket, selected_claim_halfsuit: String.to_integer(halfsuit_id))
    {:noreply, socket}
  end

  # Ask for card event
  def handle_event("ask-for-card", %{"asked_player" => asked_player, "card" => card}, socket) do
    case Players.ask_for_card(
           socket.assigns.player.id,
           asked_player,
           card,
           socket.assigns.room.id
         ) do
      {:error, reason} ->
        socket = put_flash(socket, :error, reason)
        {:noreply, socket}

      _ ->
        PubSub.broadcast!(:fish_pubsub, "room:#{socket.assigns.room_name}", "update")
        {:noreply, socket}
    end
  end

  # Create Room Event, making sure the field is not empty
  def handle_event(
        "create/delete-room",
        %{"room_to_be_created" => "", "room_to_be_deleted" => ""},
        socket
      ) do
    {:noreply, socket}
  end

  def handle_event(
        "create/delete-room",
        %{"room_to_be_created" => "", "room_to_be_deleted" => room_name},
        socket
      ) do
    Rooms.delete_room(room_name)
    socket = update(socket, :all_rooms, fn _old_list -> Rooms.list_rooms() end)
    {:noreply, socket}
  end

  def handle_event(
        "create/delete-room",
        %{"room_to_be_created" => room_name, "room_to_be_deleted" => ""},
        socket
      ) do
    case Rooms.create_room(room_name) do
      {:error, reason} ->
        socket = put_flash(socket, :error, reason)
        {:noreply, socket}

      _ ->
        socket = update(socket, :all_rooms, fn _old_list -> Rooms.list_rooms() end)
        {:noreply, socket}
    end
  end

  # Joining room event, making sure both fields are not empty upon submission
  def handle_event("join-room", %{"room_name" => "", "player_name" => _}, socket),
    do: {:noreply, socket}

  def handle_event("join-room", %{"room_name" => _, "player_name" => ""}, socket),
    do: {:noreply, socket}

  def handle_event("join-room", %{"room_name" => room_name, "player_name" => player_name}, socket) do
    case Rooms.add_player_to_room(room_name, player_name, false) do
      {:error, reason} ->
        socket = put_flash(socket, :error, reason)
        {:noreply, socket}

      player ->
        socket = update_socket_assigns(socket, room_name, player)

        socket = assign(socket, :joined_game, true)
        PubSub.subscribe(:fish_pubsub, "room:#{room_name}")
        PubSub.broadcast!(:fish_pubsub, "room:#{room_name}", "update")
        {:noreply, socket}
    end
  end

  def handle_info("update", socket) do
    socket =
      update_socket_assigns(
        socket,
        socket.assigns.room_name,
        socket.assigns.player
      )

    {:noreply, socket}
  end

  def update_socket_assigns(socket, room_name, player) do
    socket =
      assign(socket,
        room_name: room_name,
        player_name: player.name,
        room: Rooms.get_room_by_name!(room_name),
        player: Players.get_player!(player.id),
        cards_can_ask_for: Cards.cards_player_can_ask_for(Players.get_player!(player.id).hand),
        team: Teams.get_team!(player.team_id),
        teammates: Players.get_players_on_team(player.team_id),
        opponent_team: Teams.get_team!(Teams.get_opponent_team_id(player.team_id)),
        opponents: Players.get_players_on_team(Teams.get_opponent_team_id(player.team_id))
      )

    socket
  end
end
