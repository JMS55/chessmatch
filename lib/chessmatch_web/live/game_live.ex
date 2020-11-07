defmodule ChessmatchWeb.GameLive do
  use ChessmatchWeb, :live_view

  @impl true
  def mount(%{"game_id" => game_id}, _session, socket) do
    {game_id, _} = Integer.parse(game_id)

    {:ok, {role, game_instance, spectator_id}} =
      Chessmatch.GameInstanceManager.get_game_info(game_id)

    spectator_link = Routes.live_url(ChessmatchWeb.Endpoint, ChessmatchWeb.GameLive, spectator_id)

    socket =
      socket
      |> assign(:role, role)
      |> assign(:game_instance, game_instance)
      |> assign(:spectator_link, spectator_link)
      |> assign(:selection, {nil, nil})
      |> update_state()

    Process.send_after(self(), :update_state, 1000)

    {:ok, socket}
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

    game_message = parse_game_status(game_status, side_to_move)
    piece_list = Chessmatch.BinboHelper.get_piece_list(socket.assigns.role, game_instance)

    possible_moves =
      if socket.assigns.role == side_to_move &&
           game_message != "White Wins! - Black Forfeit" &&
           game_message != "Black Wins! - White Forfeit" do
        Chessmatch.BinboHelper.get_possible_moves(game_instance)
      else
        %{}
      end

    socket
    |> assign(:game_message, game_message)
    |> assign(:piece_list, piece_list)
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
        Chessmatch.BinboHelper.move_with_indices(from, selection, socket.assigns.game_instance)

        socket = socket |> update_state() |> assign(:selection, {nil, nil})
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("forfeit_match", _, socket) do
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

  defp parse_game_status(game_status, side_to_move) do
    case game_status do
      :continue ->
        if side_to_move == :black do
          "Black's Turn"
        else
          "White's Turn"
        end

      :checkmate ->
        if side_to_move == :black do
          "White Wins! - Checkmate"
        else
          "Black Wins! - Checkmate"
        end

      {:draw, :stalemate} ->
        "Draw - Stalemate"

      {:draw, :rule50} ->
        "Draw - Fifty Move Rule"

      {:draw, :insufficient_material} ->
        "Draw - Insufficient Material"

      {:draw, :threefold_repetition} ->
        "Draw - Threefold Repetition"

      {:draw, {:manual, reason}} ->
        if reason == "White Wins! - Black Forfeit" || "Black Wins! - White Forfeit" do
          reason
        else
          "Draw - #{reason}"
        end
    end
  end

  defp selectable?(i, selection, possible_moves) do
    case selection do
      {nil, nil} -> Map.has_key?(possible_moves, i)
      {from, nil} -> i == from or MapSet.member?(possible_moves[from], i)
      _ -> false
    end
  end
end
