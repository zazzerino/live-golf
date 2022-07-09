defmodule Golf.GameTest do
  use ExUnit.Case, async: true

  alias Golf.Game
  alias Golf.Game.Player

  test "game" do
    p1 = Player.new("1", "alice")
    p2 = Player.new("2", "bob")

    game_id = Golf.gen_game_id()
    game = Game.new(game_id, p1)

    assert is_struct(game)
    assert length(game.players) == 1
    assert p1.id == game.host_id
    assert game.current_player_index == 0

    game = Game.add_player(game, p2)
    assert length(game.players) == 2
  end
end
