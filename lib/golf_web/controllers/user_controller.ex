defmodule GolfWeb.UserController do
  use GolfWeb, :controller

  def update_name(conn, %{"user" => %{"name" => name}}) do
    %{"game_id" => game_id, "session_id" => player_id} = get_session(conn)

    if game_id do
      Golf.GameServer.update_player_name(game_id, player_id, name)
    end

    conn
    |> put_session(:username, name)
    |> put_flash(:info, "User logged in.")
    |> redirect(to: "/")
  end

  def forget(conn, _params) do
    conn
    |> clear_session()
    |> configure_session(renew: true)
    |> redirect(to: "/")
  end
end
