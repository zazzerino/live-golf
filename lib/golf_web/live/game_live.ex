defmodule GolfWeb.Live.GameLive do
  use GolfWeb, :live_view
  import GolfWeb.Live.Component
  # alias Golf.Game

  @impl true
  def mount(_params, session, socket) do
    # game_id = session["game_id"]

    socket =
      assign(socket,
        username: session["username"] || Golf.User.default_name(),
        session_id: session["session_id"],
        game: nil,
        trigger_submit: false
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header socket={@socket} />
    <h2>Hello Game</h2>

    <svg class="game-svg"
         width="500"
         height="600"
         viewbox="-250, -300, 500, 600"
    >
    </svg>

    <.form for={:create_game}
           action={Routes.user_path(@socket, :update_game_id)}
           phx-submit="create_game"
           phx-trigger-action={@trigger_submit}
    >
      <%= submit "Create game" %>
    </.form>

    <.footer username={@username} />
    """
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:game_state, game}, socket) do
    socket = assign(socket, game: game)
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_game", params, socket) do
    IO.inspect(params, label: "params")
    # %{session_id: session_id, username: username} = socket.assigns
    # player = Game.Player.new(session_id, username)

    # game_id = Golf.gen_game_id()
    # game = Game.new(game_id, player)

    # {:ok, _pid} = DynamicSupervisor.start_child(Golf.GameSupervisor, {GameServer, game})
    {:noreply, socket}
  end

  @impl true
  def handle_event("leave_game", _val, socket) do
    {:noreply, socket}
  end
end

    # <div class="game-buttons">
    #   <button phx-click="create_game">Create Game</button>

    #   <%= if @game do %>
    #     <%= if @game.host_id == @session_id do %>
    #       <button phx-click="start_game">Start Game</button>
    #     <% end %>

    #     <button phx-click="leave_game">Leave Game</button>
    #   <% end %>
    # </div>
