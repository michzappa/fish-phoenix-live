defmodule FishPhxLiveWeb.FishLive do
  use FishPhxLiveWeb, :live_view

  alias FishPhxLive.Rooms
  alias FishPhxLive.Teams
  alias FishPhxLive.Players
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
        team: %{},
        teammates: [],
        opponent_team: %{},
        opponents: [],
        asked_for_card: ""
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
      <h1>Fish</h1>
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

      <%= if @joined_game do %>
        <p>Room Name: <%= @room_name %></p>
        <p>Player Name: <%= @player_name %></p>
        <p>Teammates: <%= Enum.join(Enum.map(@teammates, fn teammate -> teammate.name end),", ") %>
        <p>Team Score: <%= Kernel.length(@team.claims) %> </p>
        <p>Opponents: <%= Enum.join(Enum.map(@opponents, fn opponent -> opponent.name end),", ") %>
        <p>Opponents Score: <%= Kernel.length(@opponent_team.claims) %> </p>
        <p>Hand: <%= Enum.join(@player.hand, ", ") %></p>
        <p>Last Move: <%= @room.move %></p>
        <p>Current Turn: <%= @room.turn %></p>

        <form phx-submit="ask-for-card">
          <select id="opponents-select" name="asked_player">
            <%= for opponent <- @opponents do %>
              <option value="<%= opponent.id %>"><%= opponent.name %></option>
            <% end %>
          </select>
          <input type="text" name="card" value="<%= @asked_for_card %>"
                placeholder="Card"/>
          <button type="submit">
            Ask For Card
          </button>
        </form>
      <%end %>
    """
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
        team: Teams.get_team!(player.team_id),
        teammates: Players.get_players_on_team(player.team_id),
        opponent_team: Teams.get_team!(Teams.get_opponent_team_id(player.team_id)),
        opponents: Players.get_players_on_team(Teams.get_opponent_team_id(player.team_id))
      )

    socket
  end
end
