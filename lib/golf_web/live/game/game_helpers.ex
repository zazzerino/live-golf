defmodule GolfWeb.GameHelpers do
  @type pos :: :bottom | :left | :top | :right
  @type coord :: %{x: number, y: number, rotate: number}

  @svg_width 500
  def svg_width, do: @svg_width

  @svg_height 600
  def svg_height, do: @svg_height

  @svg_viewbox "#{@svg_width / -2}, " <>
               "#{@svg_height / -2}, " <>
               "#{@svg_width}, " <>
               "#{@svg_height}"

  def svg_viewbox, do: @svg_viewbox

  @card_width 60
  def card_width, do: @card_width

  @card_height 84
  def card_height, do: @card_height

  @card_width_scale "12%"
  def card_width_scale, do: @card_width_scale

  @hand_padding 2
  def hand_padding, do: @hand_padding

  def deck_offset_started, do: -@card_width - 2

  def table_card_offset, do: @card_width + 2

  def hand_card_coord(index) do
    x =
      case index do
        i when i in [0, 3] -> -@card_width
        i when i in [2, 5] -> @card_width
        _ -> 0
      end

    y =
      case index do
        i when i in 0..2 -> @card_height
        _ -> 0
      end

    %{x: x, y: y}
  end

  @spec hand_coord(pos, number, number) :: coord
  def hand_coord(pos, width, height) do
    case pos do
      :bottom ->
        x = -@card_width / 2
        y = height / 2 - @card_height * 2
        %{x: x, y: y, rotate: 0}

      :left ->
        x = -width / 2 + @card_height * 2
        y = -@card_width / 2
        %{x: x, y: y, rotate: 90}

      :top ->
        x = @card_width / 2
        y = -height / 2 + @card_height * 2
        %{x: x, y: y, rotate: 180}

      :right ->
        x = width / 2 - @card_height * 2
        y = @card_width / 2
        %{x: x, y: y, rotate: 270}
    end
  end

  @spec hand_positions(1..4) :: [pos, ...]
  def hand_positions(player_count) do
    case player_count do
      1 -> [:right]
      2 -> [:bottom, :top]
      3 -> [:bottom, :left, :right]
      4 -> [:bottom, :left, :top, :right]
    end
  end

  @spec held_card_coord(pos, number, number) :: coord
  def held_card_coord(pos, width, height) do
    case pos do
      :bottom ->
        hand_coord(pos, width, height)

      # x = card_width() + hand_padding() * 2
      # y = height / 2 - card_height() * 1.5 - hand_padding() * 4
      # %{x: x, y: y, rotate: 0}

      :left ->
        x = -width / 2 + card_height() + hand_padding() * 4
        y = card_width() * 1.5 + hand_padding() * 4
        %{x: x, y: y, rotate: 90}

      :top ->
        # x = -card_width() * 1.5
        # y = -height / 2 + card_height() + hand_padding() * 4
        x = -card_width() * 2 - hand_padding() * 2
        y = -height / 2
        %{x: x, y: y, rotate: 0}

      :right ->
        x = width / 2 - card_height() - hand_padding() * 4
        y = -card_width() * 1.5 - hand_padding() * 4
        %{x: x, y: y, rotate: 90}
    end
  end

  @spec player_positions(User.id(), [Player.t()]) :: [{Player.t(), pos}]
  def player_positions(user_id, players) do
    positions = hand_positions(length(players))

    user_index = Enum.find_index(players, &(&1.id == user_id))
    players = Golf.rotate(players, user_index)

    Enum.zip(positions, players)
  end
end
