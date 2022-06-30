defmodule GolfWeb.Live.GameLive do
  use GolfWeb, :live_view
  import GolfWeb.Live.Component

  @impl true
  def mount(_params, session, socket) do
    socket = assign(socket, :username, session["username"])
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header socket={@socket} />
    <h2>Hello Game</h2>

    <%= if @username do %>
      <.footer username={@username} />
    <% end %>
    """
  end
end
