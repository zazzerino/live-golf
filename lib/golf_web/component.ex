defmodule GolfWeb.Component do
  use GolfWeb, :component

  def footer(assigns) do
    ~H"""
    <footer>
      <p>Logged in as <%= @user_name %></p>
    </footer>
    """
  end

  def header(assigns) do
    ~H"""
    <header>
      <nav>
        <ul>
          <li>
            <%= live_patch "home", to: Routes.live_path(@conn, GolfWeb.HomeLive) %>
          </li>
          <li>
            <%= live_patch "game", to: Routes.live_path(@conn, GolfWeb.GameLive) %>
          </li>
        </ul>
      </nav>
    </header>
    """
  end
end
