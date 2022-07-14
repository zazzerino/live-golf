defmodule GolfWeb.GameController do
  use GolfWeb, :controller

  alias Golf.Game
  alias Golf.Game.Player
  alias Golf.GameServer
  alias Golf.GameSupervisor

  def create_game(conn, _params) do
    %{"session_id" => user_id, "user_name" => user_name} = session = get_session(conn)

    if game_id = session["game_id"] do
      GameServer.remove_player(game_id, user_id)
    end

    game_id = Golf.gen_game_id()
    player = Player.new(user_id, user_name)
    game = Game.new(game_id, player)

    {:ok, _pid} = DynamicSupervisor.start_child(GameSupervisor, {GameServer, game})

    conn
    |> put_session(:game_id, game_id)
    |> redirect(to: "/game")
  end

  def leave_game(conn, _params) do
    %{"session_id" => user_id, "game_id" => game_id} = get_session(conn)
    GameServer.remove_player(game_id, user_id)

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
        %{"session_id" => user_id, "user_name" => user_name} = get_session(conn)
        player = Player.new(user_id, user_name)
        GameServer.add_player(pid, player)

        conn
        |> put_session(:game_id, game_id)
        |> redirect(to: "/game")
    end
  end
end
