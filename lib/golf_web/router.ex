defmodule GolfWeb.Router do
  use GolfWeb, :router

  defp put_session_id(conn, _opts) do
    if get_session(conn, :session_id) do
      conn
    else
      put_session(conn, :session_id, Ecto.UUID.generate())
    end
  end

  defp put_default_user_name(conn, _opts) do
    if get_session(conn, :user_name) do
      conn
    else
      put_session(conn, :user_name, Golf.User.default_name())
    end
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {GolfWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_session_id
    plug :put_default_user_name
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GolfWeb do
    pipe_through :browser

    live "/", PageLive
    live "/game", GameLive

    post "/user/name", UserController, :update_name
    post "/user/forget", UserController, :clear_session

    post "/game/create", GameController, :create_game
    post "/game/leave", GameController, :leave_game
    post "/game/join", GameController, :join_game
  end

  # Other scopes may use custom stacks.
  # scope "/api", GolfWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GolfWeb.Telemetry
    end
  end
end
