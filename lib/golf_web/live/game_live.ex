defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  import GolfWeb.Live.Component

  require Logger

  alias Phoenix.PubSub
  alias Golf.GameServer

  @impl true
  def mount(_params, session, socket) do
    game_id = session["game_id"]

    socket =
      assign(socket,
        username: session["username"],
        session_id: session["session_id"],
        game_id: game_id,
        game: nil,
        trigger_submit_create: false,
        trigger_submit_leave: false
      )

    if connected?(socket) and is_binary(game_id) do
      PubSub.subscribe(Golf.PubSub, "game:#{game_id}")
      send(self(), {:load_game, game_id})
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header socket={@socket} />

    <%= if @game do %>
      <h2><%= @game.id %></h2>
    <% else %>
      <h2>&nbsp</h2>
    <% end %>

    <svg class="game-svg"
         width="500"
         height="600"
         viewbox="-250, -300, 500, 600"
    >
      <%= if @game do %>
        <.deck state={@game.state} />
      <% end %>
    </svg>

    <div class="game-controls">
      <.form for={:create_game}
             action={Routes.game_path(@socket, :create_game)}
             phx-submit="create_game"
             phx-trigger-action={@trigger_submit_create}
      >
        <%= submit "Create game" %>
      </.form>

      <%= if @game do %>
        <.form for={:leave_game}
               action={Routes.game_path(@socket, :leave_game)}
               phx-submit="leave_game"
               phx-trigger-action={@trigger_submit_leave}
        >
          <%= submit "Leave game" %>
        </.form>
      <% end %>
    </div>

    <.footer username={@username} />
    """
  end

  @impl true
  def handle_info({:load_game, game_id}, socket) do
    case Golf.lookup_game(game_id) do
      [] ->
        Logger.warn("Game #{game_id} not found")
        {:noreply, socket}

      [{pid, _}] ->
        {:ok, game} = GameServer.fetch_state(pid)
        {:noreply, assign(socket, :game, game)}
    end
  end

  @impl true
  def handle_info({:game_state, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def handle_event("create_game", _value, socket) do
    {:noreply, assign(socket, trigger_submit_create: true)}
  end

  @impl true
  def handle_event("leave_game", _value, socket) do
    {:noreply, assign(socket, trigger_submit_leave: true)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
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
