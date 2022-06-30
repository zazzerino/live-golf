defmodule GolfWeb.Live.GameLive do
  use GolfWeb, :live_view
  import GolfWeb.Live.Component

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, :username, session["username"])
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header socket={@socket} />
    <h2>Hello Game</h2>

    <svg class="game-svg"
         width="500"
         height="600"
         viewbox="-250, -300, 500, 600"
    >
    </svg>

    <.footer username={@username} />
    """
  end
end
