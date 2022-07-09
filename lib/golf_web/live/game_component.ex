defmodule GolfWeb.GameComponent do
  use GolfWeb, :component

  def game_title(assigns) do
    ~H"""
    <%= if @game do %>
      <h2>Game <%= @game.id %></h2>
    <% else %>
      <h2>Game</h2>
    <% end %>
    """
  end

  def create_game_form(assigns) do
    ~H"""
    <.form
      for={:create_game}
      action={Routes.game_path(@socket, :create_game)}
      phx-submit="create_game"
      phx-trigger-action={@trigger}
    >
      <%= submit "Create game" %>
    </.form>
    """
  end

  def leave_game_form(assigns) do
    ~H"""
    <.form
      for={:leave_game}
      action={Routes.game_path(@socket, :leave_game)}
      phx-submit="leave_game"
      phx-trigger-action={@trigger}
    >
      <%= submit "Leave game" %>
    </.form>
    """
  end

  def start_game_form(assigns) do
    ~H"""
    <.form for={:start_game}>
      <button type="button" phx-click="start_game">Start game</button>
    </.form>
    """
  end

  @card_width_scale "12%"
  defp card_width_scale, do: @card_width_scale

  @card_width 60
  defp card_width, do: @card_width

  @card_height 84
  defp card_height, do: @card_height

  def card_image(assigns) do
    extra = assigns_to_attributes(assigns, [:class, :card_name, :x, :y])
    assigns = assign(assigns, :extra, extra)

    ~H"""
    <image
      class={"card #{@class}"}
      href={"/images/cards/#{@card_name}.svg"}
      x={@x - card_width() / 2}
      y={@y - card_height() / 2}
      width={card_width_scale()}
      {@extra}
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
      card_name="2B"
      phx-click="deck_click"
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
      card_name={@card}
      phx-click="table_card_click"
    />
    """
  end

  @hand_padding 2
  defp hand_padding, do: @hand_padding

  defp hand_card_x(index) do
    x_offset = rem(index, 3)
    card_width() * x_offset + hand_padding() * x_offset - card_width()
  end

  defp hand_card_y(index) do
    y_offset = if index < 3, do: 0, else: card_height() + hand_padding()
    y_offset - card_height() / 2
  end

  def hand(assigns) do
    ~H"""
    <g class="hand" transform={"translate(#{@coord.x}, #{@coord.y}), rotate(#{@coord.rotate})"}>
      <%= for {{card, face_down?}, index} <- Enum.with_index(@hand_cards) do %>
        <.card_image
          class={"hand_#{index}"}
          card_name={if face_down?, do: "2B", else: card}
          x={hand_card_x(index)}
          y={hand_card_y(index)}
          phx-value-index={index}
          phx-value-position={@pos}
          phx-click="hand_card_click"
        />
      <% end %>
    </g>
    """
  end

  def hand_coord(table_pos, width, height) do
    case table_pos do
      :bottom ->
        y = height / 2 - card_height() - hand_padding() * 4
        %{x: 0, y: y, rotate: 0}

      :left ->
        x = -width / 2 + card_height() + hand_padding() * 4
        %{x: x, y: 0, rotate: 90}

      :top ->
        y = -height / 2 + card_height() + hand_padding() * 4
        %{x: 0, y: y, rotate: 180}

      :right ->
        x = width / 2 - card_height() - hand_padding() * 4
        %{x: x, y: 0, rotate: 270}
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
