defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  import GolfWeb.GameComponent
  require Logger

  alias Phoenix.PubSub
  alias Golf.GameServer

  @svg_width 500
  @svg_height 600
  @svg_viewbox "#{@svg_width/-2}, #{@svg_height/-2}, #{@svg_width}, #{@svg_height}"

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
        trigger_submit_leave: false,
        svg_width: @svg_width,
        svg_height: @svg_height,
        svg_viewbox: @svg_viewbox
      )

    if connected?(socket) and is_binary(game_id) do
      PubSub.subscribe(Golf.PubSub, "game:#{game_id}")
      send(self(), {:load_game, game_id})
    end

    {:ok, socket}
  end

  def player_positions(players) do
    Enum.zip(players,
      hand_positions(length(players)))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.game_title game={@game} />

    <svg class="game-svg"
         width={@svg_width}
         height={@svg_height}
         viewbox={@svg_viewbox}
    >
      <%= if @game do %>
        <.deck state={@game.state} />

        <%= unless @game.state == :not_started do %>
          <.table_card card={hd @game.table_cards} />

          <%= for {player, pos} <- player_positions(@game.players) do %>
            <.hand
              hand_cards={player.hand}
              coord={hand_coord(pos, @svg_width, @svg_height)}
              pos={pos}
            />
          <% end %>
        <% end %>
      <% end %>
    </svg>

    <div class="game-controls">
      <.create_game_form socket={@socket} trigger={@trigger_submit_create} />

      <%= if @game do %>
        <.leave_game_form socket={@socket} trigger={@trigger_submit_leave} />

        <%= if @session_id == @game.host_id
            and @game.state == :not_started do %>
          <.start_game_form socket={@socket} />
        <% end %>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_info({:load_game, game_id}, socket) do
    case Golf.lookup_game(game_id) do
      [] ->
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
  def handle_info(:game_inactive, socket) do
    socket =
      socket
      |> assign(game_id: nil, game: nil)
      |> put_flash(:error, "Game inactive.")

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_game", _value, socket) do
    {:noreply, assign(socket, trigger_submit_create: true)}
  end

  @impl true
  def handle_event("start_game", _value, socket) do
    %{game_id: game_id, session_id: player_id} = socket.assigns
    GameServer.start_game(game_id, player_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("leave_game", _value, socket) do
    {:noreply, assign(socket, trigger_submit_leave: true)}
  end

  @impl true
  def handle_event("deck_click", _value, socket) do
    player_id = socket.assigns[:session_id]
    IO.puts("#{player_id} clicked the deck")
    {:noreply, socket}
  end

  @impl true
  def handle_event("table_card_click", _value, socket) do
    player_id = socket.assigns[:session_id]
    IO.puts("#{player_id} clicked the table card")
    {:noreply, socket}
  end

  @impl true
  def handle_event("hand_card_click", value, socket) do
    player_id = socket.assigns[:session_id]
    IO.puts("#{player_id} clicked the hand card")
    IO.inspect(value, label: "VALUE")
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
