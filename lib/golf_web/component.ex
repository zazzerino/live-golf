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

  defp deck_offset_started, do: -card_width() / 2 - 2

  def deck(assigns) do
    ~H"""
    <.card_image
      class="deck"
      x={if @state == :not_started, do: 0, else: deck_offset_started()}
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

  @hand_padding 2
  def hand_padding, do: @hand_padding

  def hand_card_x(index) do
    x_offset = rem(index, 3)
    card_width() * x_offset + hand_padding() * x_offset - card_width()
  end

  def hand_card_y(index) do
    y_offset = if index < 3, do: 0, else: card_height() + hand_padding()
    y_offset - card_height() / 2
  end

  def hand(assigns) do
    ~H"""
    <g class="hand">
      <%= for {{card, face_down}, index} <- Enum.with_index(@cards) do %>
        <.card_image
          class={"hand_#{index}"}
          card={if face_down, do: "2B", else: card}
          x={hand_card_x(index)}
          y={hand_card_y(index)}
        />
      <% end %>
    </g>
    """
  end

  def hand_coord(position, width, height) do
    case position do
      :bottom ->
        y = height / 2 - card_height() - hand_padding() * 4
        {0, y, 0}

      :left ->
        x = -width / 2 + card_height() + hand_padding() * 4
        {x, 0, 90}

      :top ->
        y = -height / 2 + card_height() + hand_padding() * 4
        {0, y, 180}

      :right ->
        x = width / 2 - card_height() - hand_padding() * 4
        {x, 0, 270}
    end
  end

  def hand_positions(player_count) do
    case player_count do
      1 -> [:bottom]
      2 -> [:bottom, :top]
      3 -> [:bottom, :left, :right]
      4 -> [:bottom, :left, :top, :right]
    end
  end
end
