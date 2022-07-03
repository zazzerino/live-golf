defmodule GolfWeb.PageLive do
  use GolfWeb, :live_view

  alias Golf.User

  @impl true
  def mount(_params, session, socket) do
    socket =
      assign(socket,
        username: session["username"],
        name_changeset: User.name_changeset(%User{}),
        trigger_submit_name: false,
        trigger_submit_forget: false
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Home</h2>

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

    <.form for={:forget}
           action={Routes.user_path(@socket, :forget)}
           phx-submit="forget"
           phx-trigger-action={@trigger_submit_forget}
    >
      <%= submit "Forget me" %>
    </.form>
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
      socket =
        socket
        |> assign(name_changeset: User.name_changeset(%User{}))
        |> put_flash(:error, "Invalid username.")

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("forget", _params, socket) do
    {:noreply, assign(socket, trigger_submit_forget: true)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
