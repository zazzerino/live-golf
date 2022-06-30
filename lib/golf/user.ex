defmodule Golf.User do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string, virtual: true
  end

  def name_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 3, max: 12)
  end
end
