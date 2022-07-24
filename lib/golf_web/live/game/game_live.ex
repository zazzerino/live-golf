defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  import GolfWeb.GameHelpers
  import GolfWeb.GameComponent

  alias Phoenix.PubSub

  alias Golf.Game
  alias Golf.GameServer

  @impl true
  def mount(_params, session, socket) do
    game_id = session["game_id"]

    socket =
      assign(socket,
        user_id: session["session_id"],
        user_name: session["user_name"],
        svg_width: svg_width(),
        svg_height: svg_height(),
        svg_viewbox: svg_viewbox(),
        trigger_submit_create: false,
        trigger_submit_leave: false,
        game_id: nil,
        playable_cards: nil,
        player_positions: nil,
        player_scores: nil,
        user_is_host: nil,
        not_started: nil,
        game_over: nil,
        last_action: nil,
        last_event: nil,
        last_event_pos: nil,
        table_card: nil,
        second_table_card: nil,
        draw_table_card_first: nil
      )

    if connected?(socket) and is_binary(game_id) do
      PubSub.subscribe(Golf.PubSub, "game:#{game_id}")
      send(self(), {:load_game, game_id})
    end

    {:ok, socket}
  end

  defp assign_game_info(socket, game) do
    user_id = socket.assigns[:user_id]
    playable_cards = Game.playable_cards(game, user_id)
    game_over = game.state == :game_over

    player_positions = player_positions(user_id, game.players)

    player_scores =
      player_positions
      |> Enum.map(fn {pos, player} -> {pos, player.name, Game.Player.score(player)} end)

    last_event = Enum.at(game.events, 0)
    last_action = if last_event, do: last_event.action

    last_event_pos = if last_event do
      player_positions
      |> Enum.find(fn {_pos, player} -> player.id == last_event.player_id end)
      |> Kernel.elem(0)
    end

    table_card = Enum.at(game.table_cards, 0)
    second_table_card = Enum.at(game.table_cards, 1)
    draw_table_card_first = table_card && last_action in [:take_from_deck, :take_from_table]

    socket
    |> assign(:game_id, game.id)
    |> assign(:game_state, game.state)
    |> assign(:playable_cards, playable_cards)
    |> assign(:player_positions, player_positions)
    |> assign(:player_scores, player_scores)
    |> assign(:user_is_host, user_id == game.host_id)
    |> assign(:not_started, game.state == :not_started)
    |> assign(:last_event, last_event)
    |> assign(:last_action, last_action)
    |> assign(:last_event_pos, last_event_pos)
    |> assign(:table_card, table_card)
    |> assign(:second_table_card, second_table_card)
    |> assign(:draw_table_card_first, draw_table_card_first)
    |> assign(:game_over, game_over)
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
    socket = assign(socket, game_id: nil)
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_game", _value, socket) do
    {:noreply, assign(socket, trigger_submit_create: true)}
  end

  @impl true
  def handle_event("start_game", _value, socket) do
    %{user_id: user_id, game_id: game_id} = socket.assigns
    GameServer.start_game(game_id, user_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("leave_game", _value, socket) do
    {:noreply, assign(socket, trigger_submit_leave: true)}
  end

  @impl true
  def handle_event("deck_click", _value, socket) do
    %{user_id: user_id, game_id: game_id, playable_cards: playable_cards} = socket.assigns

    if :deck in playable_cards do
      event = Game.Event.new(:take_from_deck, user_id)
      GameServer.handle_game_event(game_id, event)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("table_click", _value, socket) do
    %{user_id: user_id, game_id: game_id, playable_cards: playable_cards} = socket.assigns

    if :table in playable_cards do
      event = Game.Event.new(:take_from_table, user_id)
      GameServer.handle_game_event(game_id, event)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("hand_click", value, socket) do
    %{user_id: user_id, game_id: game_id, game_state: game_state, playable_cards: playable_cards} =
      socket.assigns

    %{"holder" => holder, "index" => index} = value
    index = String.to_integer(index)
    card = String.to_existing_atom("hand_#{index}")
    face_up? = Map.has_key?(value, "face_up")

    if holder == user_id and card in playable_cards do
      if game_state == :discard_or_swap and not face_up? do
        event = Game.Event.new(:swap, user_id, %{index: index})
        GameServer.handle_game_event(game_id, event)
      else
        event = Game.Event.new(:flip, user_id, %{index: index})
        GameServer.handle_game_event(game_id, event)
      end
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("held_click", _value, socket) do
    %{user_id: user_id, game_id: game_id, playable_cards: playable_cards} = socket.assigns

    if :held in playable_cards do
      event = Game.Event.new(:discard, user_id)
      GameServer.handle_game_event(game_id, event)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end
end
