defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  import GolfWeb.GameHelpers
  import GolfWeb.GameComponent

  alias Phoenix.PubSub
  alias Phoenix.LiveView.JS

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
    game_id = session["game_id"]

    socket =
      assign(socket,
        user_id: session["session_id"],
        user_name: session["user_name"],
        svg_width: @svg_width,
        svg_height: @svg_height,
        svg_viewbox: @svg_viewbox,
        trigger_submit_create: false,
        trigger_submit_leave: false,
        game: nil,
        game_id: nil,
        game_state: nil,
        playable_cards: nil
      )

    if connected?(socket) and is_binary(game_id) do
      PubSub.subscribe(Golf.PubSub, "game:#{game_id}")
      send(self(), {:load_game, game_id})
    end

    {:ok, socket}
  end

  defp assign_game_info(socket, game) do
    user_id = socket.assigns[:user_id]

    socket
    |> assign(:game, game)
    |> assign(:game_id, game.id)
    |> assign(:game_state, game.state)
    |> assign(:playable_cards, Game.playable_cards(game, user_id))
  end

  @impl true
  def handle_info({:load_game, game_id}, socket) do
    case Golf.lookup_game(game_id) do
      [] ->
        {:noreply, socket}

      [{pid, _}] ->
        {:ok, game} = GameServer.fetch_state(pid)
        socket = assign_game_info(socket, game)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:game_state, game}, socket) do
    socket = assign_game_info(socket, game)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:game_inactive, socket) do
    socket =
      socket
      |> assign(game: nil)
      |> assign(game_id: nil)
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
    %{user_id: user_id, game: game, playable_cards: playable_cards} = socket.assigns

    if :deck in playable_cards do
      event = Game.Event.new(:take_from_deck, user_id)
      GameServer.handle_game_event(game.id, event)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("table_click", _value, socket) do
    %{user_id: user_id, game: game, playable_cards: playable_cards} = socket.assigns

    if :table in playable_cards do
      event = Game.Event.new(:take_from_table, user_id)
      GameServer.handle_game_event(game.id, event)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("hand_click", value, socket) do
    %{user_id: user_id, game: game, playable_cards: playable_cards} = socket.assigns
    %{"holder" => holder, "index" => index} = value
    index = String.to_integer(index)
    card = String.to_existing_atom("hand_#{index}")
    face_up? = Map.has_key?(value, "face_up")

    if holder == user_id and card in playable_cards do
      if game.state == :discard_or_swap and not face_up? do
        event = Game.Event.new(:swap, user_id, %{index: index})
        GameServer.handle_game_event(game.id, event)
      else
        event = Game.Event.new(:flip, user_id, %{index: index})
        GameServer.handle_game_event(game.id, event)
      end
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("held_click", _value, socket) do
    %{user_id: user_id, game: game, playable_cards: playable_cards} = socket.assigns

    if :held in playable_cards do
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
