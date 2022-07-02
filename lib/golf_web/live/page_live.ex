defmodule GolfWeb.Live.PageLive do
  use GolfWeb, :live_view

  import GolfWeb.Live.Component

  alias Golf.User

  @impl true
  def mount(_params, session, socket) do
    socket =
      assign(socket,
        username: session["username"],
        name_changeset: User.name_changeset(%User{}),
        trigger_submit_name: false,
        trigger_submit_clear: false
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header socket={@socket} />

    <h2>Hello Home</h2>

    <.form let={f}
           for={@name_changeset}
           action={Routes.user_path(@socket, :update_name)}
           phx-change="validate_name"
           phx-submit="save_name"
           phx-trigger-action={@trigger_submit_name}
    >
      <%= label f, :name %>
      <%= text_input f, :name, required: true %>
      <%= error_tag f, :name %>
      <%= submit "Update name" %>
    </.form>

    <.form for={:clear_session}
           action={Routes.user_path(@socket, :clear_session)}
           phx-submit="clear_session"
           phx-trigger-action={@trigger_submit_clear}
    >
      <%= submit "Forget me" %>
    </.form>

    <%= if @username do %>
      <.footer username={@username} />
    <% end %>
    """
  end

  @impl true
  def handle_event("validate_name", %{"user" => attrs}, socket) do
    changeset =
      %User{}
      |> User.name_changeset(attrs)
      |> Map.put(:action, :validate)

    socket = assign(socket, :name_changeset, changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("save_name", %{"user" => attrs}, socket) do
    changeset = User.name_changeset(%User{}, attrs)

    if changeset.valid? do
      {:noreply, assign(socket, name_changeset: changeset, trigger_submit_name: true)}
    else
      changeset = User.name_changeset(%User{})
      {:noreply, assign(socket, name_changeset: changeset)}
    end
  end

  @impl true
  def handle_event("clear_session", _params, socket) do
    {:noreply, assign(socket, trigger_submit_clear: true)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
