defmodule ChessmatchWeb.LobbyLive do
  use ChessmatchWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :finding_game, false)}
  end

  @impl true
  def handle_event("find_game", _unsigned_params, socket) do
    if not socket.assigns.finding_game do
      Chessmatch.GameManager.queue_up()
      {:noreply, assign(socket, :finding_game, true)}
    else
      {:noreply, socket}
    end
  end

  def redirect_to_game(pid, game_id) do
    Process.send(pid, {:redirect_to_game, game_id}, [])
  end

  @impl true
  def handle_info({:redirect_to_game, game_id}, socket) do
    {:noreply,
     push_redirect(socket, to: Routes.live_path(socket, ChessmatchWeb.GameLive, game_id))}
  end
end
