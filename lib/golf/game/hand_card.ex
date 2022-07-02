defmodule Golf.Game.HandCard do
  alias __MODULE__
  alias Golf.Game.Card

  defstruct [:card, :face_down?]

  @type t :: %HandCard{
          card: Card.t,
          face_down?: boolean
        }

  def new(card, opts \\ []) do
    face_down? = Keyword.get(opts, :face_down?, true)
    %HandCard{card: card, face_down?: face_down?}
  end

  def flip_over(hand_card) do
    %HandCard{hand_card | face_down?: false}
  end

  def golf_value(%{face_down?: true}), do: :none
  def golf_value(%{card: card}), do: Card.golf_value(card)
end
