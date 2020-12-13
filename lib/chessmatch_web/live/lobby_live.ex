defmodule ChessmatchWeb.LobbyLive do
  use ChessmatchWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, :finding_game, false)
    {:ok, socket}
  end

  @impl true
  def handle_event("find_game", _unsigned_params, socket) do
    if not socket.assigns.finding_game do
      Chessmatch.GameManager.queue_up()
      socket = assign(socket, :finding_game, true)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def redirect_to_game(pid, role_id) do
    Process.send(pid, {:redirect_to_game, role_id}, [])
  end

  @impl true
  def handle_info({:redirect_to_game, role_id}, socket) do
    socket = push_redirect(socket, to: Routes.live_path(socket, ChessmatchWeb.GameLive, role_id))
    {:noreply, socket}
  end
end
