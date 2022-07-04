defmodule GolfWeb.UserController do
  use GolfWeb, :controller

  def update_name(conn, %{"user" => %{"name" => name}}) do
    %{"session_id" => player_id} = session = get_session(conn)

    if game_id = session["game_id"] do
      Golf.GameServer.update_player_name(game_id, player_id, name)
    end

    conn
    |> put_session(:username, name)
    |> put_flash(:info, "Name updated.")
    |> redirect(to: "/")
  end

  def forget(conn, _params) do
    conn
    |> clear_session()
    |> configure_session(renew: true)
    |> redirect(to: "/")
  end
end
