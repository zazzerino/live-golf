defmodule GolfWeb.GameController do
  use GolfWeb, :controller

  alias Golf.Game
  alias Golf.GameServer
  # alias Golf.GameSupervisor

  def create_game(conn, _params) do
    %{"session_id" => session_id, "username" => username} = get_session(conn)

    game_id = Golf.gen_game_id()
    player = Game.Player.new(session_id, username)
    {:ok, _pid} = DynamicSupervisor.start_child(Golf.GameSupervisor, {GameServer, {game_id, player}})

    conn
    |> put_session(:game_id, game_id)
    |> redirect(to: "/game")
  end

  def leave_game(conn, _params) do
    %{"session_id" => session_id, "game_id" => game_id} = get_session(conn)
    GameServer.remove_player(game_id, session_id)

    conn
    |> delete_session(:game_id)
    |> redirect(to: "/game")
  end
end
