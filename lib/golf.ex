defmodule Golf do
  def gen_id() do
    min = String.to_integer("100000", 36)
    max = String.to_integer("ZZZZZZ", 36)

    max
    |> Kernel.-(min)
    |> :rand.uniform()
    |> Kernel.+(min)
    |> Integer.to_string(36)
  end

  def lookup_game(game_id) do
    Registry.lookup(Golf.GameRegistry, game_id)
  end

  def gen_game_id() do
    case lookup_game(id = gen_id()) do
      # name hasn't been registered, so we'll return it
      [] -> id
      # name has been registered, so we'll recurse and try again
      _ -> gen_game_id()
    end
  end
end
