defmodule Golf.User do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :name, :string, virtual: true
    field :game_id, :string, virtual: true
    field :session_id, :string, virtual: true
  end

  @default_name "user"
  def default_name, do: @default_name

  def name_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, max: 12)
  end

  # def game_id_changeset(user, params \\ %{}) do
  #   user
  #   |> cast(params, [:game_id])
  #   |> validate_required([:game_id])
  #   |> validate_length(:game_id, is: 6)
  # end
end
