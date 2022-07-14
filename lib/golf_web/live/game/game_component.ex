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

  def card_image(assigns) do
    extra = assigns_to_attributes(assigns, [:class, :card_name, :x, :y, :highlight])
    class = "card #{assigns[:class]} #{if assigns[:highlight], do: "highlight"}"

    assigns =
      assigns
      |> assign(:class, class)
      |> assign(:extra, extra)

    ~H"""
    <image
      class={@class}
      href={"/images/cards/#{@name}.svg"}
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
      name="2B"
      x={if @state == :not_started, do: 0, else: deck_offset_started()}
      y={0}
      highlight={@highlight}
      phx-click="deck_click"
    />
    """
  end

  def table_card(assigns) do
    ~H"""
    <.card_image
      class="table"
      name={@card}
      x={table_card_offset()}
      y={0}
      highlight={@highlight}
      phx-click="table_click"
    />
    """
  end

  def hand_card_playable?(user_id, holder, state, playable_cards, index, face_up?) do
    if state == :flip_two and not face_up? do
      true
    else
      name = "hand#{index}"
      user_id == holder and name in playable_cards
    end
  end

  def hand(assigns) do
    ~H"""
    <g class="hand" transform={"translate(#{@coord.x}, #{@coord.y}), rotate(#{@coord.rotate})"}>
      <%= for {{card, face_up?}, index} <- Enum.with_index(@cards) do %>
        <.card_image
          class={"hand#{index}"}
          name={if face_up?, do: card, else: "2B"}
          x={hand_card_x(index)}
          y={hand_card_y(index)}
          highlight={if @holder == @user_id, do: "hand#{index}" in @playable_cards}
          phx-value-index={index}
          phx-value-holder={@holder}
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
      name={@card_name}
      x={@coord.x}
      y={@coord.y}
      transform={"rotate(#{@coord.rotate})"}
      highlight={@highlight}
      phx-value-holder={@holder}
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
