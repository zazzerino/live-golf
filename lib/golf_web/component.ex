defmodule GolfWeb.Component do
  use Phoenix.HTML

  import Phoenix.LiveView.Helpers
  import GolfWeb.ErrorHelpers

  alias GolfWeb.Router.Helpers, as: Routes

  def header(assigns) do
    ~H"""
    <header>
      <nav>
        <ul>
          <li>
            <%= live_patch "home", to: Routes.live_path(@conn, GolfWeb.PageLive) %>
          </li>
          <li>
            <%= live_patch "game", to: Routes.live_path(@conn, GolfWeb.GameLive) %>
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

  def update_name_form(assigns) do
    ~H"""
    <.form let={f}
           for={@name_changeset}
           action={Routes.user_path(@socket, :update_name)}
           phx-change="validate_name"
           phx-submit="save_name"
           phx-trigger-action={@trigger_submit_name}
    >
      <%= label f, :name %>
      <%= text_input f, :name, required: true %>
      <%= error_tag f, :name %>
      <%= submit "Update name" %>
    </.form>
    """
  end

  @card_width 60
  defp card_width(), do: @card_width

  @card_height 84
  defp card_height(), do: @card_height

  def card_image(assigns) do
    ~H"""
    <image
      class={"card #{@class}"}
      x={@x - card_width() / 2}
      y={@y - card_height() / 2}
      href={"/images/cards/#{@card}.svg"}
      width="12%"
    />
    """
  end

  defp deck_offset_game_started, do: -card_width() / 2 - 2

  def deck(assigns) do
    ~H"""
    <.card_image
      class="deck"
      x={if @state == :not_started, do: 0, else: deck_offset_game_started()}
      y={0}
      card="2B"
    />
    """
  end

  defp table_card_offset, do: card_width() / 2 + 2

  def table_card(assigns) do
    ~H"""
      <.card_image
        class="table-card"
        x={table_card_offset()}
        y={0}
        card={@card}
      />
    """
  end
end
