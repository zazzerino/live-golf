defmodule GolfWeb.Live.PageLive do
  use GolfWeb, :live_view
  import GolfWeb.Live.Component
  alias Golf.User

  @impl true
  def mount(_params, session, socket) do
    socket =
      assign(socket,
        username: session["username"] || User.default_name(),
        name_changeset: User.name_changeset(%User{}),
        trigger_submit: false
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
           phx-trigger-action={@trigger_submit}
    >
      <%= label f, :name %>
      <%= text_input f, :name, required: true %>
      <%= error_tag f, :name %>
      <%= submit "Update name" %>
    </.form>

    <.form for={:logout}
           action={Routes.user_path(@socket, :logout)}
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
    socket = assign(socket, name_changeset: changeset)

    if changeset.valid? do
      {:noreply, assign(socket, trigger_submit: true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
