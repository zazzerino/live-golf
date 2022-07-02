defmodule GolfWeb.UserController do
  use GolfWeb, :controller

  def update_name(conn, %{"user" => %{"name" => name}}) do
    conn = put_session(conn, :username, name)
    redirect(conn, to: "/")
  end

  def clear_session(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: "/")
  end
end
