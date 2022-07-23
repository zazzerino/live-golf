defmodule GolfWeb.GameHelpers do
  @type pos :: :bottom | :left | :top | :right

  @svg_width 500
  def svg_width, do: @svg_width

  @svg_height 500
  def svg_height, do: @svg_height

  @svg_viewbox "0, 0, #{@svg_width}, #{@svg_height}"
  def svg_viewbox, do: @svg_viewbox

  @card_width 60
  def card_width, do: @card_width

  @card_height 84
  def card_height, do: @card_height

  @card_width_scale "12%"
  def card_width_scale, do: @card_width_scale

  def card_center_x, do: -@card_width / 2
  def card_center_y, do: -@card_height / 2

  def deck_x(_not_started? = true), do: @svg_width / 2 - @card_width / 2
  def deck_x(_), do: @svg_width / 2 - @card_width

  def deck_y(), do: @svg_height / 2 - @card_height / 2

  def table_card_x, do: @svg_width / 2
  def table_card_y, do: @svg_height / 2 - @card_height / 2

  def hand_card_x(index) do
    case index do
      i when i in [0, 3] -> -@card_width * 2
      i when i in [1, 4] -> -@card_width
      i when i in [2, 5] -> 0
    end
  end

  def hand_card_y(index) do
    case index do
      i when i in 0..2 -> -@card_height
      _ -> 0
    end
  end

  @spec hand_positions(1..4) :: [pos, ...]
  def hand_positions(player_count) do
    case player_count do
      1 -> [:bottom]
      2 -> [:bottom, :top]
      3 -> [:bottom, :left, :right]
      4 -> [:bottom, :left, :top, :right]
    end
  end

  @spec player_positions(Player.id(), [Player.t()]) :: [{Player.t(), pos}]
  def player_positions(player_id, players) do
    positions = hand_positions(length(players))
    player_index = Enum.find_index(players, &(&1.id == player_id))
    players = Golf.rotate(players, player_index)
    Enum.zip(positions, players)
  end

  @spec highlight_hand_card?(User.id(), Player.id(), [any], number) :: boolean
  def highlight_hand_card?(user_id, holder, playable_cards, index) do
    card = String.to_existing_atom("hand_#{index}")
    user_id == holder and card in playable_cards
  end
end

# def hand_x(:bottom), do: @svg_width / 2 + @card_width / 2
# def hand_x(:top), do: @svg_width / 2 + @card_width / 2

# def hand_y(:bottom), do: @svg_height - @card_height
# def hand_y(:top), do: @card_height

# def held_card_x(:bottom), do: hand_x(:bottom) + @card_width / 2
# def held_card_x(:top), do: hand_x(:top) - @card_width * 2.5

# def held_card_y(:bottom), do: hand_y(:bottom) - @card_height / 2
# def held_card_y(:top), do: hand_y(:top) - @card_height / 2
