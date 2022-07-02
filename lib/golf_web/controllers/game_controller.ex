defmodule GolfWeb.GameController do
  use GolfWeb, :controller

  alias Golf.Game
  alias Golf.Game.Player
  alias Golf.GameServer
  alias Golf.GameSupervisor

  def create_game(conn, _params) do
    %{"session_id" => session_id, "username" => username} = get_session(conn)
    player = Player.new(session_id, username)

    game_id = Golf.gen_game_id()
    game = Game.new(game_id, player)
    {:ok, _pid} = DynamicSupervisor.start_child(GameSupervisor, {GameServer, game})

    conn = put_session(conn, :game_id, game_id)
    redirect(conn, to: "/game")
  end
end
