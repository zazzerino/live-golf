defmodule GolfWeb.UserController do
  use GolfWeb, :controller

  def update_name(conn, %{"user" => %{"name" => name}}) do
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
