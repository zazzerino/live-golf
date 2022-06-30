defmodule Golf.GameServer do
  use GenServer, restart: :transient
  alias Phoenix.PubSub
  alias Golf.Game
  require Logger

  @max_players 4

  # Client

  def start(game) do
    GenServer.start(__MODULE__, game, name: via_tuple(game.id))
  end

  def start_link(game) do
    GenServer.start_link(__MODULE__, game, name: via_tuple(game.id))
  end

  def fetch_state(pid) when is_pid(pid) do
    GenServer.call(pid, :fetch_state)
  end

  def fetch_state(id) when is_binary(id) do
    GenServer.call(via_tuple(id), :fetch_state)
  end

  def add_player(id, player) when is_binary(id) do
    GenServer.call(via_tuple(id), {:add_player, player})
  end

  def remove_player(id, player_id) when is_binary(id) do
    GenServer.call(via_tuple(id), {:remove_player, player_id})
  end

  def start_game(id, player_id) when is_binary(id) do
    GenServer.cast(via_tuple(id), {:start_game, player_id})
  end

  def handle_event(id, event) when is_binary(id) do
    GenServer.call(via_tuple(id), {:game_event, event})
  end

  def via_tuple(id) when is_binary(id) do
    {:via, Registry, {Golf.GameRegistry, id}}
  end

  # Server

  @impl true
  def init(game) do
    {:ok, game}
  end

  @impl true
  def handle_call(:fetch_state, _from, game) do
    {:reply, {:ok, game}, game}
  end

  @impl true
  def handle_call({:add_player, player}, _from, game)
      when is_map_key(game.players, player.id) do
    {:reply, {:error, "player already joined"}, game}
  end

  @impl true
  def handle_call({:add_player, _player}, _from, game)
      when map_size(game.players) >= @max_players do
    {:reply, {:error, "max players"}, game}
  end

  @impl true
  def handle_call({:add_player, player}, _from, %{state: :init} = game) do
    game = Game.add_player(game, player)
    {:reply, {:ok, game}, game}
  end

  @impl true
  def handle_call({:remove_player, player_id}, _from, game)
      when map_size(game.players) == 1 and game.host_id == player_id do
    {:stop, :normal, :exit, game}
  end

  @impl true
  def handle_call({:remove_player, player_id}, _from, game)
      when not is_map_key(game.players, player_id) do
    {:reply, {:error, "player not found"}, game}
  end

  @impl true
  def handle_call({:remove_player, player_id}, _from, game) do
    game = Game.remove_player(game, player_id)
    {:reply, {:ok, game}, game}
  end

  @impl true
  def handle_call({:game_event, event}, _from, game) do
    with {:ok, game} <- Game.handle_event(game, event) do
      {:reply, {:ok, game}, game}
    end
  end

  @impl true
  def handle_cast({:start_game, player_id}, game) do
    if player_id == game.host_id do
      {:ok, game} = Game.start(game)
      broadcast_game_state(game)
      {:noreply, game}
    else
      {:noreply, game}
    end
  end

  def broadcast_game_state(game) do
    PubSub.broadcast(Golf.PubSub, "game:#{game.id}", {:game_state, game})
  end
end
