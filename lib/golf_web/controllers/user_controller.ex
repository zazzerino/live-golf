defmodule GolfWeb.UserController do
  use GolfWeb, :controller
  alias Golf.GameServer

  def update_name(conn, %{"user" => %{"name" => name}}) do
    %{"session_id" => user_id} = session = get_session(conn)

    if game_id = session["game_id"] do
      GameServer.update_player_name(game_id, user_id, name)
    end

    conn
    |> put_session(:user_name, name)
    |> put_flash(:info, "Name updated.")
    |> redirect(to: "/")
  end

  def clear_session(conn, _params) do
    %{"session_id" => user_id} = session = get_session(conn)

    if game_id = session["game_id"] do
      GameServer.remove_player(game_id, user_id)
    end

    conn
    |> clear_session()
    |> configure_session(renew: true)
    |> redirect(to: "/")
  end
end
