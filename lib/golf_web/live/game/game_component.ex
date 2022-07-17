defmodule GolfWeb.GameComponent do
  use GolfWeb, :component

  import GolfWeb.GameHelpers

  alias Phoenix.LiveView.JS

  def game_title(assigns) do
    ~H"""
    <h2>
      Game <%= @game_id %>
    </h2>
    """
  end

  def card_image(assigns) do
    extra = assigns_to_attributes(assigns, [:class, :card_name, :x, :y, :highlight])
    class = "card #{assigns[:class]} #{if assigns[:highlight], do: "highlight"}"

    assigns =
      assigns
      |> assign(:x, assigns.x - card_width() / 2) # adjust x so the image is centered
      |> assign(:y, assigns.y - card_height() / 2) # adjust y so the image is centered
      |> assign(:class, class)
      |> assign(:extra, extra)

    ~H"""
    <image
      class={@class}
      href={"/images/cards/#{@name}.svg"}
      x={@x}
      y={@y}
      width={card_width_scale()}
      {@extra}
    >
      <%= if assigns[:inner_block], do: render_slot(@inner_block) %>
    </image>
    """
  end

      # class={"deck #{if @not_started, do: "float"}"}
  def deck(assigns) do
    ~H"""
    <.card_image
      class="deck"
      name="2B"
      x={if @not_started, do: 0, else: deck_offset_started()}
      y={0}
      highlight={@highlight}
      phx-click="deck_click"
    >
      <animate attributeName="y" values={"-342"} dur="1s" />
    </.card_image>
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
      <%= for {{card, face_up?}, index} <- Enum.with_index(@cards) do %>
        <.card_image
          class={"hand_#{index}"}
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
    ~H"""
    <.card_image
      class="held"
      name={@card_name}
      x={@coord.x}
      y={@coord.y}
      transform={"rotate(#{@coord.rotate})"}
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
