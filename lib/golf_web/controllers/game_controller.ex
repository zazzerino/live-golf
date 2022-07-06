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
    game = Game.new(game_id, player)

    {:ok, _pid} = DynamicSupervisor.start_child(GameSupervisor, {GameServer, game})

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
    game_id = String.upcase(game_id, :ascii)

    case Golf.lookup_game(game_id) do
      [] ->
        conn
        |> put_flash(:error, "Game not found.")
        |> redirect(to: "/")

      [{pid, _}] ->
        %{"session_id" => player_id, "username" => username} = get_session(conn)
        player = Game.Player.new(player_id, username)
        GameServer.add_player(pid, player)

        conn
        |> put_session(:game_id, game_id)
        |> put_flash(:info, "Game joined.")
        |> redirect(to: "/game")
    end
  end
end
