defmodule GolfWeb.Live.Component do
  import Phoenix.LiveView.Helpers

  alias GolfWeb.Router.Helpers, as: Routes

  def header(assigns) do
    ~H"""
    <header>
      <nav>
        <ul>
          <li>
            <%= live_patch "home", to: Routes.live_path(@socket, GolfWeb.Live.PageLive) %>
          </li>
          <li>
            <%= live_patch "game", to: Routes.live_path(@socket, GolfWeb.Live.GameLive) %>
          </li>
        </ul>
      </nav>
    </header>
    """
  end

  def footer(assigns) do
    ~H"""
    <footer>
      <%= if @username do %>
        <p>Logged in as <%= @username %></p>
      <% end %>
    </footer>
    """
  end
end
