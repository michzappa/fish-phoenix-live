defmodule FishPhxLiveWeb.FishLive do
  use FishPhxLiveWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        room_to_be_joined: "",
        joining_player_name: "",
        room_name: "",
        player_name: ""
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
      <h1>Fish</h1>
      <form phx-submit="join-room">
        <input type="text" name="room_name" value="<%= @room_to_be_joined %>"
               placeholder="Room Name"
               autofocus autocomplete="off"/>
        <input type="text" name="player_name" value="<%= @joining_player_name %>"
               placeholder="Player Name"
               autofocus autocomplete="off"/>
        <button type="submit">
          Join Room
        </button>
      </form>
      <p><%= @room_name %></p>
      <p><%= @player_name %></p>
    """
  end

  # Joining room event, making sure both fields are not empty upon submission
  def handle_event("join-room", %{"room_name" => "", "player_name" => _}, socket),
    do: {:noreply, socket}

  def handle_event("join-room", %{"room_name" => _, "player_name" => ""}, socket),
    do: {:noreply, socket}

  def handle_event("join-room", %{"room_name" => room_name, "player_name" => player_name}, socket) do
    socket =
      assign(
        socket,
        room_name: room_name,
        player_name: player_name
      )

    IO.inspect(socket)
    {:noreply, socket}
  end
end
