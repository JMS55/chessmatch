defmodule ChessmatchWeb.GameLive do
  use ChessmatchWeb, :live_view

  @impl true
  def mount(%{"game_id" => game_id}, _session, socket) do
    {game_id, _} = Integer.parse(game_id)

    {:ok, {role, game_instance_pid}} = Chessmatch.GameInstanceManager.get_game_info(game_id)
    Chessmatch.GameInstance.subscribe_to_changes(game_instance_pid)

    {game_state, board} = Chessmatch.GameInstance.get_state(game_instance_pid)

    socket =
      socket |> assign(:role, role) |> assign(:game_state, game_state) |> assign(:board, board)

    {:ok, socket}
  end
end
