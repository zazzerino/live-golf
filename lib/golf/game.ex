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
            final_turn: false,
            events: []

  @deck_count 2

  @type state :: :not_started | :flip_two | :take | :discard | :flip | :over

  @type t :: %Game{
          id: String.t(),
          state: state,
          host_id: Player.id(),
          players: [Player.t()],
          current_player_index: integer,
          deck: Deck.t(),
          table_cards: [Card.t()],
          final_turn: boolean,
          events: [Event.t()]
        }

  @spec new(String.t(), Player.t()) :: t
  def new(id, player) do
    %Game{
      id: id,
      host_id: player.id,
      players: [player],
      deck: Deck.new(@deck_count) |> Enum.shuffle()
    }
  end

  def add_player(game, player) do
    %Game{game | players: game.players ++ [player]}
  end

  defp next_index(index, list), do: rem(index + 1, length(list))

  defp next_player_index(game) do
    next_index(game.current_player_index, game.players)
  end

  def remove_player(game, player_id) when game.host_id == player_id do
    next_player = Enum.at(game.players, next_player_index(game))

    %Game{
      game
      | host_id: next_player.id,
        players: Enum.reject(game.players, &(&1.id == player_id))
    }
  end

  def remove_player(game, player_id) do
    %Game{game | players: Enum.reject(game.players, &(&1.id == player_id))}
  end

  def deal_table_card(game) do
    {:ok, card, deck} = Deck.deal(game.deck)
    table_cards = [card | game.table_cards]
    %Game{game | deck: deck, table_cards: table_cards}
  end

  defp update_player(game, player_id, fun) do
    players = Enum.map(game.players, fn p -> if p.id == player_id, do: fun.(p), else: p end)
    %Game{game | players: players}
  end

  defp deal_hands(game, player_ids) do
    Enum.reduce(player_ids, game, fn player_id, game ->
      {:ok, cards, deck} = Deck.deal(game.deck, Player.hand_size())

      game
      |> update_player(player_id, &Player.give_cards(&1, cards))
      |> Map.put(:deck, deck)
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

  @spec update_player_name(t, Player.id(), String.t()) :: t
  def update_player_name(game, player_id, new_name) do
    update_player(game, player_id, &Player.update_name(&1, new_name))
  end

  @spec player_ids(t) :: [Player.id()]
  def player_ids(game) do
    Enum.map(game.players, & &1.id)
  end

  @spec no_players?(t) :: boolean
  def no_players?(game) do
    Enum.empty?(game.players)
  end

  def handle_event(%{state: :flip_two} = game, %{action: :flip_card} = event) do
    %{player_id: player_id, data: %{index: index}} = event
    player = game.players[player_id]

    if Player.cards_facing_up(player) < 2 do
      game = update_player(game, player.id, &Player.flip_card(&1, index))
      all_ready? = Enum.all?(game.players, &Player.two_facing_up?/1)
      state = if all_ready?, do: :take, else: :flip_two
      events = [event | game.events]
      {:ok, %Game{game | state: state, events: events}}
    else
      {:error, "Player #{player_id} already flipped two"}
    end
  end
end

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

# def handle_event(%{state: :take} = game, %{action: :take_from_deck} = event) do
#   with {:ok, card, deck} <- Deck.deal(game.deck),
#        players <- Map.update!(game.players, event.player_id, &Player.hold_card(&1, card)) do
#     events = [event | game.events]
#     game = %Game{game | state: :discard, deck: deck, players: players, events: events}
#     {:ok, reset_timer(game)}
#   end
# end

# def handle_event(%{state: :take} = game, %{action: :take_from_table} = event) do
#   [card | table_cards] = game.table_cards
#   players = Map.update!(game.players, event.player_id, &Player.hold_card(&1, card))
#   events = [event | game.events]

#   game = %Game{
#     game
#     | state: :discard,
#       table_cards: table_cards,
#       players: players,
#       events: events
#   }

#   {:ok, reset_timer(game)}
# end

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
