defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  import GolfWeb.GameHelpers
  import GolfWeb.GameComponent

  require Logger

  alias Phoenix.PubSub
  alias Golf.Game
  alias Golf.GameServer

  @svg_width 500
  @svg_height 600

  @svg_viewbox "#{@svg_width / -2},
                #{@svg_height / -2},
                #{@svg_width},
                #{@svg_height}"

  @impl true
  def mount(_params, session, socket) do
    socket =
      assign(socket,
        user_id: session["session_id"],
        user_name: session["user_name"],
        game: nil,
        trigger_submit_create: false,
        trigger_submit_leave: false,
        svg_width: @svg_width,
        svg_height: @svg_height,
        svg_viewbox: @svg_viewbox
      )

    game_id = session["game_id"]

    if connected?(socket) and is_binary(game_id) do
      PubSub.subscribe(Golf.PubSub, "game:#{game_id}")
      send(self(), {:load_game, game_id})
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.game_title game={@game} />

    <svg
      class="game-svg"
      width={@svg_width}
      height={@svg_height}
      viewbox={@svg_viewbox}
    >
      <%= if @game do %>
        <.deck state={@game.state} />

        <%= unless @game.state == :not_started do %>
          <%= unless Enum.empty?(@game.table_cards) do %>
            <.table_card card={hd @game.table_cards} />
          <% end %>

          <%= for {pos, player} <- player_positions(@user_id, @game.players) do %>
            <.hand
              holder={player.id}
              cards={player.hand}
              coord={hand_coord(pos, @svg_width, @svg_height)}
            />
            <%= if player.held_card do %>
              <.held_card
                holder={player.id}
                card_name={player.held_card}
                coord={held_card_coord(pos, @svg_width, @svg_height)}
              />
            <% end %>
          <% end %>
        <% end %>
      <% end %>
    </svg>

    <div class="game-controls">
      <.create_game_form
        socket={@socket}
        trigger={@trigger_submit_create}
      />

      <%= if @game do %>
        <.leave_game_form
          socket={@socket}
          trigger={@trigger_submit_leave}
        />

        <%= if @game.state == :not_started and
               @game.host_id == @user_id do %>
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
      |> assign(game: nil)
      |> put_flash(:error, "Game inactive.")

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_game", _value, socket) do
    {:noreply, assign(socket, trigger_submit_create: true)}
  end

  @impl true
  def handle_event("start_game", _value, socket) do
    %{user_id: user_id, game: game} = socket.assigns
    GameServer.start_game(game.id, user_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("leave_game", _value, socket) do
    {:noreply, assign(socket, trigger_submit_leave: true)}
  end

  @impl true
  def handle_event("deck_click", _value, socket) do
    %{user_id: user_id, game: game} = socket.assigns

    if game.state == :take and Game.is_players_turn?(game, user_id) do
      event = Game.Event.new(:take_from_deck, user_id)
      GameServer.handle_game_event(game.id, event)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("table_card_click", _value, socket) do
    %{user_id: user_id, game: game} = socket.assigns

    if game.state == :take and Game.is_players_turn?(game, user_id) do
      event = Game.Event.new(:take_from_table, user_id)
      GameServer.handle_game_event(game.id, event)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("hand_click", value, socket) do
    %{user_id: user_id, game: game} = socket.assigns
    %{"holder" => holder, "index" => index} = value
    index = String.to_integer(index)

    if holder == user_id do
      if game.state == :flip_two or game.state == :flip do
        event = Game.Event.new(:flip, user_id, %{index: index})
        GameServer.handle_game_event(game.id, event)
      else
        if game.state == :discard_or_swap do
          event = Game.Event.new(:swap, user_id, %{index: index})
          GameServer.handle_game_event(game.id, event)
        end
      end
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("held_card_click", value, socket) do
    %{user_id: user_id, game: game} = socket.assigns
    %{"holder" => holder} = value

    if holder == user_id and game.state == :discard_or_swap do
      event = Game.Event.new(:discard, user_id)
      GameServer.handle_game_event(game.id, event)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
