defmodule ChessmatchWeb.GameLive do
  use ChessmatchWeb, :live_view

  @impl true
  def mount(%{"game_id" => game_id}, _session, socket) do
    {game_id, _} = Integer.parse(game_id)

    {:ok, {role, game_instance}} = Chessmatch.GameInstanceManager.get_game_info(game_id)

    socket =
      socket
      |> assign(:role, role)
      |> assign(:game_instance, game_instance)
      |> assign(:selection, {nil, nil})
      |> update_state()

    Process.send_after(self(), :update_state, 1000)

    {:ok, socket}
  end

  @impl true
  def handle_event("make_selection", %{"selection" => selection}, socket) do
    {selection, _} = Integer.parse(selection)

    case socket.assigns.selection do
      {nil, nil} ->
        {:noreply, assign(socket, :selection, {selection, nil})}

      {from, nil} when from == selection ->
        {:noreply, assign(socket, :selection, {nil, nil})}

      {from, nil} ->
        move = convert_piece(from) <> convert_piece(selection)
        :binbo.move(socket.assigns.game_instance, move)

        socket = socket |> update_state() |> assign(:selection, {nil, nil})
        {:noreply, socket}
    end
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
      if socket.assigns.role == :white do
        parse_fen(fen)
        |> Enum.with_index()
        |> Enum.map(fn {piece, i} -> {piece, 63 - i} end)
      else
        parse_fen(fen)
        |> Enum.with_index()
        |> Enum.map(fn {piece, i} -> {piece, 63 - i} end)
        |> Enum.reverse()
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
        {from, to} ->
          Map.update(acc, from, MapSet.new([to]), fn set -> MapSet.put(set, to) end)

        {from, to, _} ->
          Map.update(acc, from, MapSet.new([to]), fn set -> MapSet.put(set, to) end)
      end
    end)
  end

  defp convert_piece(i) do
    x = rem(i, 8)
    y = div(i, 8)

    letter =
      case x do
        0 -> "h"
        1 -> "g"
        2 -> "f"
        3 -> "e"
        4 -> "d"
        5 -> "c"
        6 -> "b"
        7 -> "a"
      end

    number =
      case y do
        0 -> "1"
        1 -> "2"
        2 -> "3"
        3 -> "4"
        4 -> "5"
        5 -> "6"
        6 -> "7"
        7 -> "8"
      end

    letter <> number
  end

  defp selectable?(i, selection, possible_moves) do
    case selection do
      {nil, nil} -> Map.has_key?(possible_moves, i)
      {from, nil} -> i == from or MapSet.member?(possible_moves[from], i)
      _ -> false
    end
  end
end
