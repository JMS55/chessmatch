defmodule ChessmatchWeb.GameLive do
  use ChessmatchWeb, :live_view

  @impl true
  def mount(%{"game_id" => game_id}, _session, socket) do
    {game_id, _} = Integer.parse(game_id)

    {:ok, {role, game_instance}} = Chessmatch.GameInstanceManager.get_game_info(game_id)

    socket =
      socket |> assign(:role, role) |> assign(:game_instance, game_instance) |> update_state()

    Process.send_after(self(), :update_state, 1000)

    {:ok, socket}
  end

  @impl true
  def handle_info(:update_state, socket) do
    Process.send_after(self(), :update_state, 1000)
    {:noreply, update_state(socket)}
  end

  defp update_state(socket) do
    game_instance = socket.assigns.game_instance

    {:ok, game_status} = :binbo.game_status(game_instance)
    {:ok, side_to_move} = :binbo.side_to_move(game_instance)
    {:ok, legal_moves} = :binbo.all_legal_moves(game_instance)
    {:ok, fen} = :binbo.get_fen(game_instance)

    game_message = parse_game_status(game_status, side_to_move)

    piece_list =
      if socket.assigns.role == :black do
        Enum.reverse(parse_fen(fen))
      else
        parse_fen(fen)
      end

    possible_moves =
      if socket.assigns.role == side_to_move do
        parse_legal_moves(legal_moves)
      else
        %{}
      end

    socket
    |> assign(:game_message, game_message)
    |> assign(:piece_list, piece_list)
    |> assign(:possible_moves, possible_moves)
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
        "Checkmate"

      {:draw, :stalemate} ->
        "Draw - Stalemate"

      {:draw, :rule50} ->
        "Draw - Fifty Move Rule"

      {:draw, :insufficient_material} ->
        "Draw - Insufficient Material"

      {:draw, :threefold_repetition} ->
        "Draw - Threefold Repetition"

      {:draw, {:manual, _}} ->
        "Draw - Manual"
    end
  end

  defp parse_fen(fen, piece_list \\ []) do
    {c, tail} = String.next_grapheme(fen)

    case c do
      " " ->
        piece_list

      "/" ->
        parse_fen(tail, piece_list)

      "1" ->
        parse_fen(tail, piece_list ++ List.duplicate({nil, nil}, 1))

      "2" ->
        parse_fen(tail, piece_list ++ List.duplicate({nil, nil}, 2))

      "3" ->
        parse_fen(tail, piece_list ++ List.duplicate({nil, nil}, 3))

      "4" ->
        parse_fen(tail, piece_list ++ List.duplicate({nil, nil}, 4))

      "5" ->
        parse_fen(tail, piece_list ++ List.duplicate({nil, nil}, 5))

      "6" ->
        parse_fen(tail, piece_list ++ List.duplicate({nil, nil}, 6))

      "7" ->
        parse_fen(tail, piece_list ++ List.duplicate({nil, nil}, 7))

      "8" ->
        parse_fen(tail, piece_list ++ List.duplicate({nil, nil}, 8))

      "p" ->
        parse_fen(tail, piece_list ++ [{:pawn, :black}])

      "n" ->
        parse_fen(tail, piece_list ++ [{:knight, :black}])

      "b" ->
        parse_fen(tail, piece_list ++ [{:bishop, :black}])

      "r" ->
        parse_fen(tail, piece_list ++ [{:rook, :black}])

      "q" ->
        parse_fen(tail, piece_list ++ [{:queen, :black}])

      "k" ->
        parse_fen(tail, piece_list ++ [{:king, :black}])

      "P" ->
        parse_fen(tail, piece_list ++ [{:pawn, :white}])

      "N" ->
        parse_fen(tail, piece_list ++ [{:knight, :white}])

      "B" ->
        parse_fen(tail, piece_list ++ [{:bishop, :white}])

      "R" ->
        parse_fen(tail, piece_list ++ [{:rook, :white}])

      "Q" ->
        parse_fen(tail, piece_list ++ [{:queen, :white}])

      "K" ->
        parse_fen(tail, piece_list ++ [{:king, :white}])
    end
  end

  defp parse_legal_moves(legal_moves) do
    Enum.reduce(legal_moves, %{}, fn move, acc ->
      case move do
        {from, to} -> Map.update(acc, 63 - from, [], fn list -> list ++ [63 - to] end)
        {from, to, _} -> Map.update(acc, 63 - from, [], fn list -> list ++ [63 - to] end)
      end
    end)
  end
end
