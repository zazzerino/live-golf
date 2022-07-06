defmodule Golf.GameServer do
  use GenServer, restart: :transient

  require Logger

  alias Phoenix.PubSub
  alias Golf.Game

  @max_players 4
  @inactivity_timeout 1000 * 30 * 1

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

  def start_game(id, player_id) when is_binary(id) do
    GenServer.cast(via_tuple(id), {:start_game, player_id})
  end

  def add_player(pid, player) when is_pid(pid) do
    GenServer.cast(pid, {:add_player, player})
  end

  def add_player(id, player) when is_binary(id) do
    GenServer.cast(via_tuple(id), {:add_player, player})
  end

  def remove_player(id, player_id) when is_binary(id) do
    GenServer.cast(via_tuple(id), {:remove_player, player_id})
  end

  def handle_event(id, event) when is_binary(id) do
    GenServer.cast(via_tuple(id), {:game_event, event})
  end

  def update_player_name(id, player_id, new_name) when is_binary(id) do
    GenServer.cast(via_tuple(id), {:update_player_name, player_id, new_name})
  end

  defp via_tuple(id) when is_binary(id) do
    {:via, Registry, {Golf.GameRegistry, id}}
  end

  # Server

  @type timer_ref :: reference()
  @type state :: {Game.t(), timer_ref()}

  @impl true
  def init(game) do
    {:ok, {game, set_timer()}}
  end

  @impl true
  def handle_call(:fetch_state, _from, {game, _timer} = state) do
    {:reply, {:ok, game}, state}
  end

  @impl true
  def handle_cast({:start_game, player_id}, {game, timer})
      when player_id == game.host_id and
             game.state == :not_started do
    game = Game.start(game)
    broadcast_game_state(game)
    {:noreply, {game, reset_timer(timer)}}
  end

  @impl true
  def handle_cast({:start_game, _player_id}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_player, player}, {game, timer} = state)
      when length(game.players) < @max_players do
    unless player.id in Enum.map(game.players, & &1.id) do
      game = Game.add_player(game, player)
      broadcast_game_state(game)
      {:noreply, {game, reset_timer(timer)}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:remove_player, player_id}, {game, timer} = state) do
    if player_id in Game.player_ids(game) do
      game = Game.remove_player(game, player_id)
      broadcast_game_state(game)
      {:noreply, {game, reset_timer(timer)}}
    else
      {:noreply, state}
    end
  end

  # @impl true
  # def handle_cast({:game_event, event}, game) do
  #   # {:ok, game} = Game.handle_event(game, event)
  #   # broadcast_game_state(game)
  #   {:noreply, game}
  # end

  @impl true
  def handle_cast({:update_player_name, player_id, new_name}, {game, timer}) do
    game = Game.update_player_name(game, player_id, new_name)
    broadcast_game_state(game)
    {:noreply, {game, reset_timer(timer)}}
  end

  @impl true
  def handle_info(:inactivity_timeout, {game, _timer} = state) do
    Logger.info("Game #{game.id} was ended for inactivity")
    PubSub.broadcast(Golf.PubSub, "game:#{game.id}", :game_inactive)
    {:stop, :normal, state}
  end

  defp broadcast_game_state(game) do
    PubSub.broadcast(Golf.PubSub, "game:#{game.id}", {:game_state, game})
  end

  defp set_timer() do
    Process.send_after(self(), :inactivity_timeout, @inactivity_timeout)
  end

  defp cancel_timer(timer) do
    Process.cancel_timer(timer)
  end

  defp reset_timer(timer) do
    cancel_timer(timer)
    set_timer()
  end
end

# defp set_timer(game) do
#   %Game{game | timer: Process.send_after(self(), :inactivity_timeout, @inactivity_timeout)}
# end

# defp cancel_timer(%Game{timer: timer} = game) when is_reference(timer) do
#   Process.cancel_timer(timer)
#   %Game{game | timer: nil}
# end

# defp cancel_timer(game), do: game

# defp reset_timer(game) do
#   game
#   |> cancel_timer()
#   |> set_timer()
# end
