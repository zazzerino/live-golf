defmodule GolfWeb.Live.PageLive do
  use GolfWeb, :live_view
  import GolfWeb.Live.Component
  alias Golf.User

  @impl true
  def mount(_params, session, socket) do
    socket =
      assign(socket,
        username: session["username"],
        name_changeset: User.name_changeset(%User{})
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header socket={@socket} />

    <h2>Hello Home</h2>

    <.form
      let={f}
      for={@name_changeset}
      action={Routes.user_path(@socket, :update_name)}
    >
      <%= label f, :name %>
      <%= text_input f, :name, required: true %>
      <%= error_tag f, :name %>
      <%= submit "Update name", class: "update-name-button" %>
    </.form>

    <.form
      for={:logout}
      action={Routes.user_path(@socket, :logout)}
    >
      <%= submit "Forget me", class: "logout-button" %>
    </.form>

    <%= if @username do %>
      <.footer username={@username} />
    <% end %>
    """
  end
end
