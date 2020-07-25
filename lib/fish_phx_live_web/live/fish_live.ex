defmodule FishPhxLiveWeb.FishLive do
  use FishPhxLiveWeb, :live_view

  alias FishPhxLive.Rooms
  alias FishPhxLive.Teams
  alias FishPhxLive.Players

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
        opponents: []
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
        <input type="text" name="room_name" value="<%= @room_to_be_joined %>"
               placeholder="Room Name"/>
        <input type="text" name="player_name" value="<%= @joining_player_name %>"
               placeholder="Player Name"/>
        <button type="submit">
          Join Room
        </button>
      </form>
      <ul>
        <%= for room <- @all_rooms do %>
            <li><%= room.name %> </li>
        <% end %>
      </ul>

      <%= if @joined_game do %>
        <p>Room Name: <%= @room_name %></p>
        <p>Player Name: <%= @player_name %></p>
        <ul>
          Teammates
          <%= for teammate <- @teammates do %>
            <li><%= teammate.name %> </li>
          <% end %>
        </ul>
        <p>Team Score: <%= Kernel.length(@team.claims) %> </p>
        <ul>
          Opponents
          <%= for opponent <- @opponents do %>
            <li><%= opponent.name %> </li>
          <% end %>
        </ul>
        <p>Opponents Score: <%= Kernel.length(@opponent_team.claims) %> </p>
        <p>Hand: <%= @player.hand %></p>
        <p>Last Move: <%= @room.move %></p>
        <p>Current Turn: <%= @room.turn %></p>
      <%end %>
    """
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
    Rooms.create_room(room_name)
    socket = update(socket, :all_rooms, fn _old_list -> Rooms.list_rooms() end)
    {:noreply, socket}
  end

  # Joining room event, making sure both fields are not empty upon submission
  def handle_event("join-room", %{"room_name" => "", "player_name" => _}, socket),
    do: {:noreply, socket}

  def handle_event("join-room", %{"room_name" => _, "player_name" => ""}, socket),
    do: {:noreply, socket}

  def handle_event("join-room", %{"room_name" => room_name, "player_name" => player_name}, socket) do
    case Rooms.add_player_to_room(room_name, player_name, false) do
      {:error, _reason} ->
        {:noreply, socket}

      player ->
        socket = update_socket_assigns(socket, room_name, player)

        socket = assign(socket, :joined_game, true)
        {:noreply, socket}
    end
  end

  def update_socket_assigns(socket, room_name, player) do
    socket =
      assign(socket,
        room_name: room_name,
        player_name: player.name,
        room: Rooms.get_room_by_name!(room_name),
        player: player,
        team: Teams.get_team!(player.team_id),
        teammates: Players.get_players_on_team(player.team_id),
        opponent_team: Teams.get_team!(Teams.get_opponent_team_id(player.team_id)),
        opponents: Players.get_players_on_team(Teams.get_opponent_team_id(player.team_id))
      )

    socket
  end
end
