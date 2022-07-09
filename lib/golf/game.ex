defmodule Golf.Game do
  alias __MODULE__
  alias __MODULE__.{Card, Deck, Event, Player}

  defstruct id: nil,
            state: :not_started,
            host_id: nil,
            players: [],
            current_player_index: 0,
            deck: [],
            table_cards: [],
            final_turn?: false,
            events: []

  @deck_count 2

  @type id :: binary
  @type state ::
          :not_started | :flip_two | :take | :discard_or_swap | :flip | :game_over

  @type t :: %Game{
          id: id,
          state: state,
          host_id: Player.id(),
          players: [Player.t()],
          current_player_index: integer,
          deck: Deck.t(),
          table_cards: [Card.t()],
          final_turn?: boolean,
          events: [Event.t()]
        }

  @spec new(id, Player.t()) :: t
  def new(id, player) do
    deck = Deck.new(@deck_count) |> Enum.shuffle()

    %Game{
      id: id,
      host_id: player.id,
      players: [player],
      deck: deck
    }
  end

  @spec add_player(t, Player.t()) :: t
  def add_player(game, player) do
    %Game{game | players: game.players ++ [player]}
  end

  defp next_index(index, len), do: rem(index + 1, len)

  defp next_player_index(game) do
    next_index(game.current_player_index, length(game.players))
  end

  defp reject_matching_id(maps, id) do
    Enum.reject(maps, fn m -> m.id == id end)
  end

  @spec remove_player(t, Player.id()) :: t
  def remove_player(game, player_id) when game.host_id == player_id do
    next_player = Enum.at(game.players, next_player_index(game))

    %Game{
      game
      | host_id: next_player.id,
        players: reject_matching_id(game.players, player_id)
    }
  end

  def remove_player(game, player_id) do
    %Game{game | players: reject_matching_id(game.players, player_id)}
  end

  @spec deal_table_card(t) :: t
  def deal_table_card(game) do
    {:ok, card, deck} = Deck.deal(game.deck)
    table_cards = [card | game.table_cards]
    %Game{game | deck: deck, table_cards: table_cards}
  end

  defp update_matching_id(maps, id, fun) do
    Enum.map(maps, fn m -> if m.id == id, do: fun.(m), else: m end)
  end

  defp deal_hands(game, player_ids) do
    Enum.reduce(player_ids, game, fn player_id, game ->
      {:ok, cards, deck} = Deck.deal(game.deck, Player.hand_size())
      players = update_matching_id(game.players, player_id, &Player.give_cards(&1, cards))
      %Game{game | deck: deck, players: players}
    end)
  end

  @spec deal_hands(t) :: t
  def deal_hands(game) do
    deal_hands(game, player_ids(game))
  end

  @spec start(t) :: t
  def start(game) do
    game
    |> deal_hands()
    |> deal_table_card()
    |> Map.put(:state, :flip_two)
  end

  @spec update_player_name(t, Player.id(), binary) :: t
  def update_player_name(game, player_id, new_name) do
    players = update_matching_id(game.players, player_id, &Player.update_name(&1, new_name))
    %Game{game | players: players}
  end

  @spec player_ids(t) :: [Player.id()]
  def player_ids(game) do
    Enum.map(game.players, & &1.id)
  end

  @spec no_players?(t) :: boolean
  def no_players?(game) do
    Enum.empty?(game.players)
  end

  @spec find_player(t, Player.id()) :: Player.t() | nil
  def find_player(game, player_id) do
    Enum.find(game.players, fn p -> p.id == player_id end)
  end

  @spec find_player_index(t, Player.id()) :: non_neg_integer | nil
  def find_player_index(game, player_id) do
    Enum.find_index(game.players, fn p -> p.id == player_id end)
  end

  @spec is_players_turn?(t, Player.id()) :: boolean
  def is_players_turn?(game, player_id) do
    game.current_player_index ==
      find_player_index(game, player_id)
  end

  @spec handle_event(t, any) :: {:ok, t} | {:error, binary}
  def handle_event(%{state: :flip_two} = game, %{action: :flip} = event) do
    %{player_id: player_id, data: %{index: index}} = event
    player = find_player(game, player_id)

    if Player.cards_face_up(player) < 2 do
      players = update_matching_id(game.players, player.id, &Player.flip_card(&1, index))
      all_ready? = Enum.all?(players, &Player.two_face_up?/1)
      state = if all_ready?, do: :take, else: :flip_two
      events = [event | game.events]
      game = %Game{game | state: state, players: players, events: events}
      {:ok, game}
    else
      {:error, "Player #{player_id} already flipped two"}
    end
  end

  def handle_event(%{state: :take} = game, %{action: :take_from_deck} = event) do
    {:ok, card, deck} = Deck.deal(game.deck)
    players = update_matching_id(game.players, event.player_id, &Player.hold_card(&1, card))
    state = :discard_or_swap
    events = [event | game.events]
    game = %Game{game | state: state, deck: deck, players: players, events: events}
    {:ok, game}
  end

  def handle_event(%{state: :take} = game, %{action: :take_from_table} = event) do
    [card | table_cards] = game.table_cards
    players = update_matching_id(game.players, event.player_id, &Player.hold_card(&1, card))
    events = [event | game.events]

    game = %Game{
      game
      | state: :discard_or_swap,
        table_cards: table_cards,
        players: players,
        events: events
    }

    {:ok, game}
  end

  def handle_event(%{state: :discard_or_swap} = game, %{action: :discard} = event) do
    player = find_player(game, event.player_id)
    card = player.held_card
    table_cards = [card | game.table_cards]
    players = update_matching_id(game.players, player.id, &Player.discard/1)
    events = [event | game.events]

    {state, current_player_index} =
      if Player.one_face_down?(player) do
        {:take, next_player_index(game)}
      else
        {:flip, game.current_player_index}
      end

    game = %Game{
      game
      | state: state,
        players: players,
        table_cards: table_cards,
        current_player_index: current_player_index,
        events: events
    }

    {:ok, game}
  end
end

# def handle_event(%{state: :discard} = game, %{action: :discard} = event) do
#   player = game.players[event.player_id]
#   {card, player} = Player.discard(player)
#   players = Map.replace!(game.players, event.player_id, player)

#   table_cards = [card | game.table_cards]
#   events = [event | game.events]

#   {state, next_player_id} =
#     if Player.flipped_card_count(player) === Player.hand_size() - 1 do
#       {:take, next_item(game.player_order, event.player_id)}
#     else
#       {:flip, game.next_player_id}
#     end

#   game = %Game{
#     game
#     | state: state,
#       players: players,
#       table_cards: table_cards,
#       next_player_id: next_player_id,
#       events: events
#   }

#   {:ok, reset_timer(game)}
# end

# def handle_event(%{state: :discard} = game, %{action: :swap_card} = event) do
#   %{player_id: player_id, data: %{hand_index: hand_index}} = event

#   player = game.players[player_id]
#   {card, player} = Player.swap_card(player, hand_index)
#   players = Map.replace!(game.players, player_id, player)

#   table_cards = [card | game.table_cards]
#   next_player_id = next_item(game.player_order, player_id)

#   {state, final_turn?} = check_game_over(player_id, players, game.final_turn?)
#   events = [event | game.events]

#   game = %Game{
#     game
#     | state: state,
#       players: players,
#       table_cards: table_cards,
#       next_player_id: next_player_id,
#       final_turn?: final_turn?,
#       events: events
#   }

#   {:ok, reset_timer(game)}
# end

# defp check_game_over(player_id, players, final_turn?) do
#   all_flipped? = Enum.all?(Map.values(players), &Player.all_flipped?/1)
#   state = if all_flipped?, do: :over, else: :take

#   player_flipped? = Player.all_flipped?(players[player_id])
#   final_turn? = if player_flipped?, do: true, else: final_turn?

#   {state, final_turn?}
# end

# def handle_event(%{final_turn?: true} = game, %{action: :flip} = event) do
#   %{player_id: player_id, data: %{hand_index: hand_index}} = event
#   events = [event | game.events]
#   players = Map.update!(game.players, event.player_id, &Player.flip_card(&1, hand_index))
#   next_player_id = next_item(game.player_order, player_id)
#   {state, final_turn?} = check_game_over(player_id, players, game.final_turn?)

#   game = %Game{
#     game
#     | state: state,
#       players: players,
#       next_player_id: next_player_id,
#       final_turn?: final_turn?,
#       events: events
#   }

#   {:ok, reset_timer(game)}
# end
