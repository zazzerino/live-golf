defmodule Golf.Game do
  alias __MODULE__
  alias __MODULE__.{Card, Deck, Event, Player}

  defstruct [
    :id,
    :timer,
    :state,
    :host_id,
    :next_player_id,
    deck: [],
    table_cards: [],
    player_order: [],
    players: %{},
    final_turn?: false,
    events: []
  ]

  @deck_count 2
  @max_players 4

  @inactivity_timeout 1000 * 60 * 20

  @type id :: String.t
  @type state :: :not_started | :flip_two | :take | :discard | :flip | :over

  @type t :: %Game{
          id: id,
          timer: reference | nil,
          state: state,
          deck: Deck.t,
          table_cards: [Card.t],
          player_order: [Player.id],
          players: %{Player.id => Player.t},
          host_id: Player.id,
          next_player_id: Player.id,
          final_turn?: boolean,
          events: [Event.t]
        }

  @spec new(id, Player.t) :: t
  def new(id, player) do
    deck = Deck.new(@deck_count) |> Enum.shuffle()

    %Game{
      id: id,
      state: :not_started,
      deck: deck,
      players: %{player.id => player},
      player_order: [player.id],
      host_id: player.id,
      next_player_id: player.id
    }
    |> set_timer()
  end

  @spec add_player(t, Player.t) :: {:ok, t} | {:error, String.t}
  def add_player(game, _player)
      when length(game.player_order) >= @max_players do
    {:error, "max players"}
  end

  def add_player(game, player) do
    players = Map.put(game.players, player.id, player)
    player_order = game.player_order ++ [player.id]
    game = %Game{game | players: players, player_order: player_order}

    {:ok, reset_timer(game)}
  end

  @spec remove_player(t, Player.id) :: t
  def remove_player(%{host_id: host_id, next_player_id: next_player_id} = game, player_id)
      when host_id === player_id
      and next_player_id === player_id do
    host_id = next_player_id = next_item(game.player_order, player_id)
    {players, player_order} = remove_game_player(game, player_id)

    %Game{
      game
      | players: players,
        player_order: player_order,
        host_id: host_id,
        next_player_id: next_player_id
    }
    |> reset_timer()
  end

  def remove_player(%{host_id: host_id} = game, player_id)
      when host_id == player_id do
    host_id = next_item(game.player_order, player_id)
    {players, player_order} = remove_game_player(game, player_id)

    %Game{game | players: players, player_order: player_order, host_id: host_id}
    |> reset_timer()
  end

  def remove_player(%{next_player_id: next_player_id} = game, player_id)
      when next_player_id == player_id do
    next_player_id = next_item(game.player_order, player_id)
    {players, player_order} = remove_game_player(game, player_id)

    %Game{game | players: players, player_order: player_order, next_player_id: next_player_id}
    |> reset_timer()
  end

  def remove_player(game, player_id) do
    {players, player_order} = remove_game_player(game, player_id)

    %Game{game | players: players, player_order: player_order}
    |> reset_timer()
  end

  @spec start(t) :: {:ok, t} | Deck.deal_error
  def start(game) when game.state == :not_started do
    with {:ok, game} <- deal_hands(game),
         {:ok, game} <- deal_table_card(game) do
      game = %Game{game | state: :flip_two}
      {:ok, reset_timer(game)}
    end
  end

  def start(game), do: game

  @spec handle_event(t, Event.t) :: {:ok, t}
  def handle_event(%{state: :flip_two} = game, %{action: :flip_card} = event) do
    %{player_id: player_id, data: %{hand_index: hand_index}} = event

    if Player.flipped_two?(game.players[player_id]) do
      {:ok, game}
    else
      players = Map.update!(game.players, player_id, &Player.flip_card(&1, hand_index))
      all_flipped_two? = Enum.all?(Map.values(players), &Player.flipped_two?/1)
      state = if all_flipped_two?, do: :take, else: game.state
      events = [event | game.events]

      game = %Game{game | state: state, players: players, events: events}
      {:ok, reset_timer(game)}
    end
  end

  def handle_event(%{state: :flip} = game, %{action: :flip_card} = event) do
    %{player_id: player_id, data: %{hand_index: hand_index}} = event
    events = [event | game.events]
    players = Map.update!(game.players, event.player_id, &Player.flip_card(&1, hand_index))
    next_player_id = next_item(game.player_order, player_id)
    {state, final_turn?} = check_game_over(player_id, players, game.final_turn?)

    game = %Game{
      game
      | state: state,
        players: players,
        next_player_id: next_player_id,
        final_turn?: final_turn?,
        events: events
    }

    {:ok, reset_timer(game)}
  end

  def handle_event(%{final_turn?: true} = game, %{action: :flip} = event) do
    %{player_id: player_id, data: %{hand_index: hand_index}} = event
    events = [event | game.events]
    players = Map.update!(game.players, event.player_id, &Player.flip_card(&1, hand_index))
    next_player_id = next_item(game.player_order, player_id)
    {state, final_turn?} = check_game_over(player_id, players, game.final_turn?)

    game = %Game{
      game
      | state: state,
        players: players,
        next_player_id: next_player_id,
        final_turn?: final_turn?,
        events: events
    }

    {:ok, reset_timer(game)}
  end

  def handle_event(%{state: :take} = game, %{action: :take_from_deck} = event) do
    with {:ok, card, deck} <- Deck.deal(game.deck),
         players <- Map.update!(game.players, event.player_id, &Player.hold_card(&1, card)) do
      events = [event | game.events]
      game = %Game{game | state: :discard, deck: deck, players: players, events: events}
      {:ok, reset_timer(game)}
    end
  end

  def handle_event(%{state: :take} = game, %{action: :take_from_table} = event) do
    [card | table_cards] = game.table_cards
    players = Map.update!(game.players, event.player_id, &Player.hold_card(&1, card))
    events = [event | game.events]

    game = %Game{
      game
      | state: :discard,
        table_cards: table_cards,
        players: players,
        events: events
    }

    {:ok, reset_timer(game)}
  end

  def handle_event(%{state: :discard} = game, %{action: :discard} = event) do
    player = game.players[event.player_id]
    {card, player} = Player.discard(player)
    players = Map.replace!(game.players, event.player_id, player)

    table_cards = [card | game.table_cards]
    events = [event | game.events]

    {state, next_player_id} =
      if Player.flipped_card_count(player) === Player.hand_size() - 1 do
        {:take, next_item(game.player_order, event.player_id)}
      else
        {:flip, game.next_player_id}
      end

    game = %Game{
      game
      | state: state,
        players: players,
        table_cards: table_cards,
        next_player_id: next_player_id,
        events: events
    }

    {:ok, reset_timer(game)}
  end

  def handle_event(%{state: :discard} = game, %{action: :swap_card} = event) do
    %{player_id: player_id, data: %{hand_index: hand_index}} = event

    player = game.players[player_id]
    {card, player} = Player.swap_card(player, hand_index)
    players = Map.replace!(game.players, player_id, player)

    table_cards = [card | game.table_cards]
    next_player_id = next_item(game.player_order, player_id)

    {state, final_turn?} = check_game_over(player_id, players, game.final_turn?)
    events = [event | game.events]

    game = %Game{
      game
      | state: state,
        players: players,
        table_cards: table_cards,
        next_player_id: next_player_id,
        final_turn?: final_turn?,
        events: events
    }

    {:ok, reset_timer(game)}
  end

  def no_players?(game), do: Enum.empty?(game.players)

  def change_player_name(game, player_id, new_name) do
    update_in(game.players[player_id],
              &(Player.change_name(&1, new_name)))
  end

  defp deal_table_card(game) do
    with {:ok, card, deck} <- Deck.deal(game.deck) do
      table_cards = [card | game.table_cards]
      game = %Game{game | deck: deck, table_cards: table_cards}
      {:ok, game}
    end
  end

  defp deal_hand(game, player_id) do
    with {:ok, cards, deck} <- Deck.deal(game.deck, Player.hand_size()),
         players <- Map.update!(game.players, player_id, &Player.give_cards(&1, cards)) do
      game = %Game{game | deck: deck, players: players}
      {:ok, game}
    end
  end

  defp deal_to_player_ids(game, []) do
    game
  end

  defp deal_to_player_ids(game, [player_id | player_ids]) do
    with {:ok, game} <- deal_hand(game, player_id) do
      deal_to_player_ids(game, player_ids)
    end
  end

  defp deal_hands(game) do
    game = deal_to_player_ids(game, game.player_order)
    {:ok, game}
  end

  defp next_item(list, item) do
    if index = Enum.find_index(list, &(&1 == item)) do
      last_item? = index == length(list) - 1

      if last_item? do
        Enum.at(list, 0)
      else
        Enum.at(list, index + 1)
      end
    end
  end

  defp remove_game_player(game, player_id) do
    players = Map.delete(game.players, player_id)
    player_order = Enum.reject(game.player_order, &(&1 == player_id))
    {players, player_order}
  end

  defp check_game_over(player_id, players, final_turn?) do
    all_flipped? = Enum.all?(Map.values(players), &Player.all_flipped?/1)
    state = if all_flipped?, do: :over, else: :take

    player_flipped? = Player.all_flipped?(players[player_id])
    final_turn? = if player_flipped?, do: true, else: final_turn?

    {state, final_turn?}
  end

  defp set_timer(game) do
    %Game{game | timer: Process.send_after(self(), :inactivity_timeout, @inactivity_timeout)}
  end

  defp cancel_timer(%Game{timer: timer} = game) when is_reference(timer) do
    Process.cancel_timer(timer)
    %Game{game | timer: nil}
  end

  defp cancel_timer(game), do: game

  defp reset_timer(game) do
    game
    |> cancel_timer()
    |> set_timer()
  end
end
