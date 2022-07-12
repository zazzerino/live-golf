defmodule GolfWeb.HomeComponent do
  use GolfWeb, :component

  def update_name_form(assigns) do
    ~H"""
    <.form
      let={f}
      for={@changeset}
      action={Routes.user_path(@socket, :update_name)}
      phx-change="validate_name"
      phx-submit="change_name"
      phx-trigger-action={@trigger}
    >
      <%= label f, :name %>
      <%= text_input f, :name, required: true %>
      <%= error_tag f, :name %>
      <%= submit "Update name" %>
    </.form>
    """
  end

  def clear_session_form(assigns) do
  ~H"""
  <.form
    for={:clear_session}
    action={Routes.user_path(@socket, :clear_session)}
    phx-submit="clear_session"
    phx-trigger-action={@trigger}
  >
    <%= submit "Forget me" %>
  </.form>
  """
  end

  def join_game_form(assigns) do
    ~H"""
    <.form
      let={f}
      for={@changeset}
      action={Routes.game_path(@socket, :join_game)}
      phx-change="validate_game"
      phx-submit="join_game"
      phx-trigger-action={@trigger}
    >
      <%= label f, :game_id %>
      <%= text_input f, :game_id, required: true %>
      <%= error_tag f, :game_id %>
      <%= submit "Join game" %>
    </.form>
    """
  end
end
