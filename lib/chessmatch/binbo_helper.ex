defmodule Chessmatch.BinboHelper do
  def get_board(role, game_instance) do
    {:ok, pieces_list} = :binbo.get_pieces_list(game_instance, :index)

    if role == :white do
      pieces_list
      |> fill_in_pieces_list
    else
      pieces_list
      |> fill_in_pieces_list
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

  def parse_game_status(game_status, side_to_move) do
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
        if reason == "White Wins! - Black Forfeit" or reason == "Black Wins! - White Forfeit" do
          reason
        else
          "Draw - #{reason}"
        end
    end
  end

  defp fill_in_pieces_list(pieces_list, expected_i \\ 63, result \\ []) do
    if expected_i < 0 do
      result
    else
      case pieces_list do
        [] ->
          fill_in_pieces_list(pieces_list, expected_i - 1, result ++ [{expected_i, nil, nil}])

        [piece | tail] ->
          {i, _, _} = piece

          if i == expected_i do
            fill_in_pieces_list(tail, expected_i - 1, result ++ [piece])
          else
            fill_in_pieces_list(pieces_list, expected_i - 1, result ++ [{expected_i, nil, nil}])
          end
      end
    end
  end
end
