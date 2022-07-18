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

  def deck_offset, do: -@card_width / 2

  def deck_offset_started, do: -@card_width - 2

  def table_card_offset, do: @card_width + 2

  def hand_card_coord(index) do
    x =
      case index do
        i when i in [0, 3] -> -@card_width * 1.5
        i when i in [1, 4] -> -@card_width / 2
        i when i in [2, 5] -> @card_width / 2
      end

    y =
      case index do
        i when i in 0..2 -> -@card_height
        _ -> 0
      end

    %{x: x, y: y}
  end

  @spec hand_coord(pos, number, number) :: coord
  def hand_coord(pos, width, height) do
    case pos do
      :bottom ->
        x = 0
        y = height / 2 - @card_height
        %{x: x, y: y, rotate: 0}

      :left ->
        x = -width / 2 + @card_height
        y = 0
        %{x: x, y: y, rotate: 90}

      :top ->
        x = 0
        y = -height / 2 + @card_height
        %{x: x, y: y, rotate: 180}

      :right ->
        x = width / 2 - @card_height
        y = 0
        %{x: x, y: y, rotate: 270}
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

  # @spec held_card_coord(pos, number, number) :: coord
  # def held_card_coord(pos, width, height) do
  #   case pos do
  #     :bottom ->
  #       hand_coord(pos, width, height)
  #       |> Map.update!(:x, &(&1 + card_width() * 1.5))

  #     :left ->
  #       hand_coord(pos, width, height)
  #       |> Map.update!(:y, &(&1 + card_width() * 1.5))

  #     :top ->
  #       hand_coord(pos, width, height)
  #       |> Map.update!(:x, &(&1 - card_width() * 1.5))

  #     :right ->
  #       hand_coord(pos, width, height)
  #       |> Map.update!(:y, &(&1 - card_width() * 1.5))
  #   end
  # end

  @spec player_positions(Player.id(), [Player.t()]) :: [{Player.t(), pos}]
  def player_positions(player_id, players) do
    positions = hand_positions(length(players))
    player_index = Enum.find_index(players, &(&1.id == player_id))
    players = Golf.rotate(players, player_index)
    Enum.zip(positions, players)
  end
end
