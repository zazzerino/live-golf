defmodule GolfWeb.GameController do
  use GolfWeb, :controller

  alias Golf.Game
  alias Golf.GameServer
  alias Golf.GameSupervisor

  def create_game(conn, _params) do
    %{"session_id" => player_id, "username" => username} = session = get_session(conn)

    if game_id = session["game_id"] do
      GameServer.remove_player(game_id, player_id)
    end

    game_id = Golf.gen_game_id()
    player = Game.Player.new(player_id, username)

    {:ok, _pid} = DynamicSupervisor.start_child(GameSupervisor, {GameServer, {game_id, player}})

    conn
    |> put_session(:game_id, game_id)
    |> redirect(to: "/game")
  end

  def leave_game(conn, _params) do
    %{"session_id" => player_id, "game_id" => game_id} = get_session(conn)
    GameServer.remove_player(game_id, player_id)

    conn
    |> delete_session(:game_id)
    |> redirect(to: "/game")
  end

  def join_game(conn, %{"user" => %{"game_id" => game_id}}) do
    %{"session_id" => session_id, "username" => username} = get_session(conn)
    _player = Game.Player.new(session_id, username)
    # GameServer.add

    conn
    |> put_session(:game_id, game_id)
    |> redirect(to: "/game")
  end
end
