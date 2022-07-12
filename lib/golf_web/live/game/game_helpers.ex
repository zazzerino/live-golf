defmodule GolfWeb.GameHelpers do
  @type pos :: :bottom | :left | :top | :right
  @type coord :: %{x: number, y: number, rotate: integer}

  @card_width 60
  def card_width, do: @card_width

  @card_height 84
  def card_height, do: @card_height

  @card_width_scale "12%"
  def card_width_scale, do: @card_width_scale

  @hand_padding 2
  def hand_padding, do: @hand_padding

  def deck_offset_started, do: -card_width() / 2 - 2

  def table_card_offset, do: card_width() / 2 + 2

  def hand_card_x(index) do
    x_offset = rem(index, 3)
    card_width() * x_offset + hand_padding() * x_offset - card_width()
  end

  def hand_card_y(index) do
    y_offset = if index < 3, do: 0, else: card_height() + hand_padding()
    y_offset - card_height() / 2
  end

  @spec hand_coord(pos, number, number) :: coord
  def hand_coord(pos, width, height) do
    case pos do
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

  @spec hand_positions(1..4) :: [pos, ...]
  def hand_positions(player_count) do
    case player_count do
      1 -> [:bottom]
      2 -> [:bottom, :top]
      3 -> [:bottom, :left, :right]
      4 -> [:bottom, :left, :top, :right]
    end
  end

  @spec player_positions(User.id(), [Player.t()]) :: [{Player.t(), pos}]
  def player_positions(user_id, players) do
    positions = hand_positions(length(players))
    user_index = Enum.find_index(players, &(&1.id == user_id))
    players = Golf.rotate(players, user_index)
    Enum.zip(positions, players)
  end

  @spec held_card_coord(pos, number, number) :: coord
  def held_card_coord(pos, width, height) do
    case pos do
      :bottom ->
        x = card_width() * 1.5
        y = height / 2 - card_height() - hand_padding() * 4
        %{x: x, y: y, rotate: 0}

      :left ->
        x = -width / 2 + card_height() + hand_padding() * 4
        y = card_width() * 1.5 + hand_padding() * 4
        %{x: x, y: y, rotate: 90}

      :top ->
        x = -card_width() * 1.5
        y = -height / 2 + card_height() + hand_padding() * 4
        %{x: x, y: y, rotate: 0}

      :right ->
        x = width / 2 - card_height() - hand_padding() * 4
        y = -card_width() * 1.5 - hand_padding() * 4
        %{x: x, y: y, rotate: 90}
    end
  end
end
