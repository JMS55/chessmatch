defmodule ChessmatchWeb.LobbyLive do
  use ChessmatchWeb, :live_view

  def redirect_to_game(pid, game_id) do
    GenServer.call(pid, {:redirect_to_game, game_id})
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("queue_up", _unsigned_params, socket) do
    Chessmatch.GameInstanceManager.queue_up()
    {:noreply, socket}
  end

  @impl true
  def handle_call({:redirect_to_game, game_id}, _, socket) do
    {:noreply,
     push_redirect(socket, to: Routes.live_path(socket, ChessmatchWeb.ChessGameLive, game_id))}
  end
end
