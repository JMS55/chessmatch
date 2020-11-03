defmodule Chessmatch.BinboHelper do
  def get_piece_list(role, game_instance) do
    {:ok, fen} = :binbo.get_fen(game_instance)

    if role == :white do
      parse_fen(fen)
      |> Enum.with_index()
      |> Enum.map(fn {{piece, color}, i} ->
        {piece, color, div(63 - i, 8) * 8 + (7 - rem(63 - i, 8))}
      end)
    else
      parse_fen(fen)
      |> Enum.with_index()
      |> Enum.map(fn {{piece, color}, i} ->
        {piece, color, div(63 - i, 8) * 8 + (7 - rem(63 - i, 8))}
      end)
      |> Enum.reverse()
    end
  end

  def get_possible_moves(game_instance) do
    {:ok, legal_moves} = :binbo.all_legal_moves(game_instance)

    Enum.reduce(legal_moves, %{}, fn move, acc ->
      case move do
        {from, to} ->
          Map.update(acc, from, MapSet.new([to]), fn set -> MapSet.put(set, to) end)

        {from, to, _} ->
          Map.update(acc, from, MapSet.new([to]), fn set -> MapSet.put(set, to) end)
      end
    end)
  end

  def move_with_indices(from, to, game_instance) do
    move = convert_piece(from) <> convert_piece(to)
    :binbo.move(game_instance, move)
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

  defp convert_piece(i) do
    x = rem(i, 8)
    y = div(i, 8)

    letter =
      case x do
        0 -> "a"
        1 -> "b"
        2 -> "c"
        3 -> "d"
        4 -> "e"
        5 -> "f"
        6 -> "g"
        7 -> "h"
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
end
