defmodule FishPhxLiveWeb.FishLive do
  use FishPhxLiveWeb, :live_view

  alias FishPhxLive.Rooms

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        joined_game: false,
        room_to_be_created: "",
        room_to_be_joined: "",
        joining_player_name: "",
        room_name: "",
        player_name: "",
        all_rooms: Rooms.list_rooms()
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
      <h1>Fish</h1>
      <form phx-submit="create-room">
        <input type="text" name="room_name" value="<%= @room_to_be_created %>"
              placeholder="Room Name"/>
        <button type="submit">
          Create Room
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
      <p><%= @room_name %></p>
      <p><%= @player_name %></p>
      <%= if @joined_game do %>
        <p><%= @player.hand %></p>
      <%end %>
    """
  end

  # Create Room Event, making sure the field is not empty
  def handle_event("create-room", %{"room_name" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("create-room", %{"room_name" => room_name}, socket) do
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
        socket =
          assign(
            socket,
            room_name: room_name,
            player_name: player_name,
            player: player
          )
          socket = update(socket, :joined_game, fn _ -> true end)
        {:noreply, socket}
    end
  end
end
