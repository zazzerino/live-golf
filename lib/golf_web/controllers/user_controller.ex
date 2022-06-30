defmodule GolfWeb.UserController do
  use GolfWeb, :controller

  def update_name(conn, %{"user" => %{"name" => name}}) do
    conn = put_session(conn, :username, name)
    redirect(conn, to: "/")
  end

  def logout(conn, _params) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
    |> redirect(to: "/")
  end
end
