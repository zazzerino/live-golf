defmodule GolfWeb.Live.GameLive do
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
        trigger_submit: false
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
    <h2>Hello Game</h2>

    <svg class="game-svg"
         width="500"
         height="600"
         viewbox="-250, -300, 500, 600"
    >
    </svg>

    <%= if @game_id do %>
      <p>Game: <%= @game_id %></p>
    <% end %>

    <.form for={:create_game}
           action={Routes.game_path(@socket, :create_game)}
           phx-submit="create_game"
           phx-trigger-action={@trigger_submit}
    >
      <%= submit "Create game" %>
    </.form>

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
  def handle_event("create_game", _val, socket) do
    {:noreply, assign(socket, trigger_submit: true)}
  end

  @impl true
  def handle_event("leave_game", _val, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  # component functions

  def card_image(assigns) do
    ~H"""
    <image
      class={"card #{@class}"}
      x={@x - 30}
      y={@y - 42}
      href={"/images/cards/#{@card}.svg"}
      width="12%"
    />
    """
  end

  def deck(assigns) do
    ~H"""
    <.card_image
      class="deck"
      x={if @state == :init, do: 0, else: -32}
      y={0}
      card="2B"
    />
    """
  end

  def table_card(assigns) do
    ~H"""
      <.card_image
        class="table-card"
        x={32}
        y={0}
        card={@card}
      />
    """
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
