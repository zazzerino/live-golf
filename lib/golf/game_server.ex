defmodule Golf.GameServer do
  use GenServer, restart: :transient
  require Logger

  alias Phoenix.PubSub
  alias Golf.Game

  # Client

  def start({game_id, player}) do
    GenServer.start(__MODULE__, {game_id, player}, name: via_tuple(game_id))
  end

  def start_link({game_id, player}) do
    GenServer.start_link(__MODULE__, {game_id, player}, name: via_tuple(game_id))
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

  def remove_player(id, player_id) when is_binary(id) do
    GenServer.cast(via_tuple(id), {:remove_player, player_id})
  end

  def update_player_name(id, player_id, new_name) when is_binary(id) do
    GenServer.cast(via_tuple(id), {:update_player_name, player_id, new_name})
  end

  defp via_tuple(id) when is_binary(id) do
    {:via, Registry, {Golf.GameRegistry, id}}
  end

  # Server

  @impl true
  def init({game_id, player}) do
    {:ok, Game.new(game_id, player)}
  end

  @impl true
  def handle_call(:fetch_state, _from, game) do
    {:reply, {:ok, game}, game}
  end

  @impl true
  def handle_cast({:start_game, player_id}, game)
      when player_id == game.host_id
      and game.state == :not_started do
    {:ok, game} = Game.start(game)
    broadcast_game_state(game)
    {:noreply, game}
  end

  @impl true
  def handle_cast({:start_game, _player_id}, game) do
    {:noreply, game}
  end

  @impl true
  def handle_cast({:add_player, player}, game) do
    case Game.add_player(game, player) do
      {:ok, game} ->
        broadcast_game_state(game)
        {:noreply, game}

      _ ->
        {:noreply, game}
    end
  end

  @impl true
  def handle_cast({:remove_player, player_id}, game) do
    game = Game.remove_player(game, player_id)

    if Game.no_players?(game) do
      Logger.info("Game #{game.id} was ended because all players left")
      {:stop, :normal, game}
    else
      broadcast_game_state(game)
      {:noreply, game}
    end
  end

  @impl true
  def handle_cast({:update_player_name, player_id, new_name}, game) do
    game = Game.change_player_name(game, player_id, new_name)
    broadcast_game_state(game)
    {:noreply, game}
  end

  @impl true
  def handle_info(:inactivity_timeout, game) do
    Logger.info("Game #{game.id} was ended for inactivity")
    {:stop, :normal, game}
  end

  defp broadcast_game_state(game) do
    PubSub.broadcast(Golf.PubSub, "game:#{game.id}", {:game_state, game})
  end
end

# def handle_event(id, event) when is_binary(id) do
#   GenServer.call(via_tuple(id), {:game_event, event})
# end

# @impl true
# def handle_call({:game_event, event}, _from, game) do
#   with {:ok, game} <- Game.handle_event(game, event) do
#     {:reply, {:ok, game}, game}
#   end
# end
