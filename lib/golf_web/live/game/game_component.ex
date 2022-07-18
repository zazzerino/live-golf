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
    x = assigns[:x] || card_width() / 2
    y = assigns[:y] || -card_height() / 2
    class = "card #{assigns[:class]} #{if assigns[:highlight], do: "highlight"}"
    extra = assigns_to_attributes(assigns, [:class, :card_name, :x, :y, :highlight])
    assigns = assign(assigns, x: x, y: y, class: class, extra: extra)

    ~H"""
    <image
      class={@class}
      href={"/images/cards/#{@name}.svg"}
      x={@x}
      y={@y}
      width={card_width_scale()}
      {@extra}
    />
    """
  end

  def deck(assigns) do
    x = if assigns.not_started, do: -card_width() / 2, else: deck_offset_started()
    y = -card_height() / 2
    class = "deck #{if assigns.not_started, do: "deal"}"
    assigns = assign(assigns, x: x, y: y, class: class)

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
    assigns = assign(assigns, x: 2, y: -card_height() / 2)

    ~H"""
    <.card_image
      class="table"
      name={@card}
      x={@x}
      y={@y}
      highlight={@highlight}
      phx-click="table_click"
    />
    """
  end

  def hand_card(assigns) do
    ~H"""
    <.card_image
     class={"hand_#{@index}"}
     name={if @face_up, do: @card, else: "2B"}
     x={@coord.x}
     y={@coord.y}
     highlight={@highlight}
     phx-value-index={@index}
     phx-value-holder={@holder}
     phx-value-face-up={@face_up}
     phx-click="hand_click"
    />
    """
  end

  defp highlight_hand_card?(user_id, holder, playable_cards, index) do
    card = String.to_existing_atom("hand_#{index}")
    user_id == holder and card in playable_cards
  end

  def hand(assigns) do
    ~H"""
    <g
      class="hand"
      transform={"translate(#{@coord.x}, #{@coord.y}), rotate(#{@coord.rotate})"}
    >
      <%= for {{card, face_up}, index} <- Enum.with_index(@cards) do %>
        <.hand_card
          card={card}
          index={index}
          holder={@holder}
          face_up={face_up}
          coord={hand_card_coord(index)}
          highlight={highlight_hand_card?(@user_id, @holder, @playable_cards, index)}
        />
      <% end %>
    </g>
    """
  end

  def held_card(assigns) do
    ~H"""
    <.card_image
      class="held"
      name={@card_name}
      transform={"translate(#{@coord.x}, #{@coord.y}) rotate(#{@coord.rotate})"}
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
