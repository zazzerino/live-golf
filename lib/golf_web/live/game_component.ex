defmodule GolfWeb.GameComponent do
  use GolfWeb, :component

  import GolfWeb.GameHelpers

  def game_title(assigns) do
    ~H"""
    <h2>
      Game <%= if @game, do: @game.id %>
    </h2>
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

  def deck(assigns) do
    ~H"""
    <.card_image
      class="deck"
      card_name="2B"
      x={if @state == :not_started, do: 0, else: deck_offset_started()}
      y={0}
      phx-click="deck_click"
    />
    """
  end

  def table_card(assigns) do
    ~H"""
    <.card_image
      class="table-card"
      card_name={@card}
      x={table_card_offset()}
      y={0}
      phx-click="table_card_click"
    />
    """
  end

          # card_name={if face_up?, do: card, else: "2B"}
  def hand(assigns) do
    IO.inspect(assigns.pos)
    ~H"""
    <g class="hand" transform={"translate(#{@coord.x}, #{@coord.y}), rotate(#{@coord.rotate})"}>
      <%= for {{card, _face_up?}, index} <- Enum.with_index(@cards) do %>
        <.card_image
          class={"hand_#{index}"}
          card_name={card}
          x={hand_card_x(index)}
          y={hand_card_y(index)}
          phx-value-pos={@pos}
          phx-value-index={index}
          phx-click="hand_click"
        />
      <% end %>
    </g>
    """
  end

  def held_card(assigns) do
    ~H"""
    <.card_image
      class="held"
      card_name={@card_name}
      x={@coord.x}
      y={@coord.y}
      transform={"rotate(#{@coord.rotate})"}
      phx-value-pos={@pos}
      phx-click="held_card_click"
    />
    """
  end
end
