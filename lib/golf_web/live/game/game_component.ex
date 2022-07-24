defmodule GolfWeb.GameComponent do
  use GolfWeb, :component

  import GolfWeb.GameHelpers

  def game_title(assigns) do
    ~H"""
    <h2>
      Game <%= @game_id %>
    </h2>
    """
  end

  def card_image(assigns) do
    x = assigns[:x] || card_center_x()
    y = assigns[:y] || card_center_y()
    width = card_width_scale()

    highlight = if assigns[:highlight], do: "highlight"
    class = "card #{assigns[:class]} #{highlight}"
    extra = assigns_to_attributes(assigns, [:class, :card_name, :x, :y, :highlight])
    assigns = assign(assigns, x: x, y: y, width: width, class: class, extra: extra)

    ~H"""
    <image
      class={@class}
      href={"/images/cards/#{@name}.svg"}
      x={@x}
      y={@y}
      width={@width}
      {@extra}
    />
    """
  end

  def deck(assigns) do
    not_started? = assigns[:not_started]
    class = "deck #{if not_started?, do: "not-started"}"

    assigns =
      assign(assigns,
        class: class,
        x: deck_x(not_started?),
        y: deck_y()
      )

    ~H"""
    <.card_image
      class={@class}
      name="2B"
      x={@x}
      y={@y}
      highlight={@highlight}
      phx-click="deck_click"
    />
    """
  end

  def table_card(assigns) do
    animation =
      case assigns.last_action do
        :discard ->
          "slide-from-held-#{assigns.last_event_pos}"

        :swap ->
          "slide-from-hand-#{assigns.last_event.data.index}-#{assigns.last_event_pos}"

        _ ->
          nil
      end

    class = if animation, do: "table #{animation}", else: "table"
    assigns = assign(assigns, x: table_card_x(), y: table_card_y(), class: class)

    ~H"""
    <.card_image
      class={@class}
      name={@card}
      x={@x}
      y={@y}
      highlight={@highlight}
      phx-click="table_click"
    />
    """
  end

  def second_table_card(assigns) do
    assigns = assign(assigns,
      x: table_card_x(),
      y: table_card_y())

    ~H"""
    <.card_image
      name={@card}
      x={@x}
      y={@y}
    />
    """
  end

  def hand(assigns) do
    ~H"""
    <g class={"hand #{@pos}"}>
      <%= for {{card, face_up?}, index} <- Enum.with_index(@hand_cards) do %>
        <.card_image
         class={"hand-card hand-#{index}"}
         name={if face_up?, do: card, else: "2B"}
         x={hand_card_x(index)}
         y={hand_card_y(index)}
         highlight={highlight_hand_card?(@user_id, @holder, @playable_cards, index)}
         phx-value-index={index}
         phx-value-holder={@holder}
         phx-value-face-up={face_up?}
         phx-click="hand_click"
        />
      <% end %>
    </g>
    """
  end

  def held_card(assigns) do
    animation =
      case assigns[:last_action] do
        :take_from_deck -> "slide-from-deck"
        :take_from_table -> "slide-from-table"
        _ -> nil
      end

    class = "held #{assigns.pos} #{animation}"
    assigns = assign(assigns, class: class)

    ~H"""
    <.card_image
      class={@class}
      name={@card_name}
      highlight={@highlight}
      phx-click="held_click"
    />
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
      <button type="button" phx-click="start_game">
        Start game
      </button>
    </.form>
    """
  end
end
