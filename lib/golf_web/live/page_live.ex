  defmodule GolfWeb.PageLive do
  use GolfWeb, :live_view

  import GolfWeb.PageComponent

  alias Golf.User

  @impl true
  def mount(_params, session, socket) do
    socket =
      assign(socket,
        username: session["username"],
        name_changeset: User.name_changeset(%User{}),
        game_changeset: User.game_id_changeset(%User{}),
        trigger_submit_name: false,
        trigger_submit_join: false,
        trigger_submit_clear: false
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Home</h2>

    <.update_name_form
      socket={@socket}
      changeset={@name_changeset}
      trigger={@trigger_submit_name}
    />

    <.clear_session_form
      socket={@socket}
      trigger={@trigger_submit_clear}
    />
    """
  end

  # @impl true
  # def render(assigns) do
  #   ~H"""
  #   <h2>Home</h2>

  #   <.form let={f}
  #          for={@game_changeset}
  #          action={Routes.game_path(@socket, :join_game)}
  #          phx-change="validate_game"
  #          phx-submit="join_game"
  #          phx-trigger-action={@trigger_submit_join}
  #   >
  #     <%= label f, :game_id %>
  #     <%= text_input f, :game_id, required: true %>
  #     <%= error_tag f, :game_id %>
  #     <%= submit "Join game" %>
  #   </.form>
  #   """
  # end

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
  def handle_event("change_name", %{"user" => attrs}, socket) do
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
  def handle_event("validate_game", %{"user" => attrs}, socket) do
    changeset =
      %User{}
      |> User.game_id_changeset(attrs)
      |> Map.put(:action, :validate)

    socket = assign(socket, :game_changeset, changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("join_game", %{"user" => attrs}, socket) do
    changeset = User.game_id_changeset(%User{}, attrs)

    if changeset.valid? do
      {:noreply, assign(socket, game_changeset: changeset, trigger_submit_join: true)}
    else
      socket =
        socket
        |> assign(game_changeset: User.game_id_changeset(%User{}))
        |> put_flash(:error, "Invalid game id.")

      {:noreply, socket}
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
