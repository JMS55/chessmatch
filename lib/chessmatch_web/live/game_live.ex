defmodule ChessmatchWeb.GameLive do
  use ChessmatchWeb, :live_view

  @impl true
  def mount(%{"game_id" => game_id}, _session, socket) do
    with {game_id, ""} <- Integer.parse(game_id),
         {:ok, {role, game_instance, spectator_id}} <-
           Chessmatch.GameInstanceManager.get_game_info(game_id) do
      spectator_link =
        Routes.live_url(ChessmatchWeb.Endpoint, ChessmatchWeb.GameLive, spectator_id)

      socket =
        socket
        |> assign(:role, role)
        |> assign(:game_instance, game_instance)
        |> assign(:spectator_link, spectator_link)
        |> assign(:selection, {nil, nil})
        |> assign(:forfeit_dialog_open, false)
        |> update_state()

      Process.send_after(self(), :update_state, 1000)

      {:ok, socket}
    else
      _ -> Phoenix.Router.MalformedURIError
    end
  end

  @impl true
  def handle_info(:update_state, socket) do
    socket = update_state(socket)
    Process.send_after(self(), :update_state, 1000)
    {:noreply, socket}
  end

  defp update_state(socket) do
    game_instance = socket.assigns.game_instance

    {:ok, game_status} = :binbo.game_status(game_instance)
    {:ok, side_to_move} = :binbo.side_to_move(game_instance)

    game_message = Chessmatch.BinboHelper.parse_game_status(game_status, side_to_move)
    board = Chessmatch.BinboHelper.get_board(socket.assigns.role, game_instance)

    possible_moves =
      if socket.assigns.role == side_to_move and
           game_message != "White Wins! - Black Forfeit" and
           game_message != "Black Wins! - White Forfeit" do
        Chessmatch.BinboHelper.get_possible_moves(game_instance)
      else
        %{}
      end

    socket
    |> assign(:game_message, game_message)
    |> assign(:board, board)
    |> assign(:possible_moves, possible_moves)
  end

  @impl true
  def handle_event("select_piece", %{"selection" => selection}, socket) do
    {selection, _} = Integer.parse(selection)

    case socket.assigns.selection do
      {nil, nil} ->
        {:noreply, assign(socket, :selection, {selection, nil})}

      {from, nil} when from == selection ->
        {:noreply, assign(socket, :selection, {nil, nil})}

      {from, nil} ->
        :binbo.index_move(socket.assigns.game_instance, from, selection)

        socket = socket |> update_state() |> assign(:selection, {nil, nil})
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_forfeit_dialog", _, socket) do
    socket = assign(socket, :forfeit_dialog_open, not socket.assigns.forfeit_dialog_open)
    {:noreply, socket}
  end

  @impl true
  def handle_event("forfeit_match", _, socket) do
    socket = assign(socket, :forfeit_dialog_open, not socket.assigns.forfeit_dialog_open)

    :binbo.game_draw(
      socket.assigns.game_instance,
      if socket.assigns.role == :black do
        "White Wins! - Black Forfeit"
      else
        "Black Wins! - White Forfeit"
      end
    )

    {:noreply, update_state(socket)}
  end

  defp selectable?(i, selection, possible_moves) do
    case selection do
      {nil, nil} -> Map.has_key?(possible_moves, i)
      {from, nil} -> i == from or MapSet.member?(possible_moves[from], i)
      _ -> false
    end
  end

  defp piece_color(color) do
    if color == :black do
      "bg-gradient-to-b from-gray-700 to-gray-900 bg-clip-text text-transparent"
    else
      "bg-gradient-to-b from-gray-200 to-gray-500 bg-clip-text text-transparent"
    end
  end
end
