defmodule ChessmatchWeb.GameLive do
  use ChessmatchWeb, :live_view

  @impl true
  def mount(%{"game_id" => game_id}, _session, socket) do
    with {game_id, ""} <- Integer.parse(game_id),
         {:ok, {role, game_instance, spectator_id}} <-
           Chessmatch.GameManager.get_game_info(game_id) do
      spectator_link = Routes.live_url(socket, ChessmatchWeb.GameLive, spectator_id)

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

    selected_other_piece = Map.has_key?(socket.assigns.possible_moves, selection)

    case socket.assigns.selection do
      {nil, nil} ->
        {:noreply, assign(socket, :selection, {selection, nil})}

      {from, nil} when from == selection ->
        {:noreply, assign(socket, :selection, {nil, nil})}

      {_from, nil} when selected_other_piece ->
        {:noreply, assign(socket, :selection, {selection, nil})}

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
      {nil, nil} ->
        if Map.has_key?(possible_moves, i) do
          2
        else
          0
        end

      {from, nil} ->
        cond do
          i == from or MapSet.member?(possible_moves[from], i) -> 1
          Map.has_key?(possible_moves, i) -> 2
          true -> 0
        end
    end
  end

  defp border(i, selection, possible_moves) do
    case selectable?(i, selection, possible_moves) do
      0 -> ""
      1 -> "border-2 bl:border-4 border-blue-500 border-opacity-75"
      2 -> "border-2 bl:border-4 border-gray-200 border-opacity-50"
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
