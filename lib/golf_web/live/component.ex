defmodule GolfWeb.Live.Component do
  import Phoenix.LiveView.Helpers

  alias GolfWeb.Router.Helpers, as: Routes

  def header(assigns) do
    ~H"""
    <header>
      <nav>
        <ul>
          <li>
            <%= live_patch "home", to: Routes.live_path(@socket, GolfWeb.PageLive) %>
          </li>
          <li>
            <%= live_patch "game", to: Routes.live_path(@socket, GolfWeb.GameLive) %>
          </li>
        </ul>
      </nav>
    </header>
    """
  end

  def footer(assigns) do
    ~H"""
    <footer>
      <p>Logged in as <%= @username %></p>
    </footer>
    """
  end

  def card_image(assigns) do
    ~H"""
    <image
      class={"card #{@class}"}
      x={@x - 30}
      y={@y - 42}
      href={"/images/cards/#{@card}.svg"}
      width="12%"
    />
    """
  end

  def deck(assigns) do
    ~H"""
    <.card_image
      class="deck"
      x={if @state == :init, do: 0, else: -32}
      y={0}
      card="2B"
    />
    """
  end

  def table_card(assigns) do
    ~H"""
      <.card_image
        class="table-card"
        x={32}
        y={0}
        card={@card}
      />
    """
  end
end
