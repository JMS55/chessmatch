defmodule ChessmatchWeb.GameLiveSubview do
  use ChessmatchWeb, :view

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

  defp square_color(i, last_move) do
    if rem(i, 2) != rem(div(i, 8), 2) do
      case last_move do
        {m1, m2} when i == m1 or i == m2 ->
          "bg-gradient-to-tl from-gray-400 to-gray-500 inset-shadow2 bl:inset-shadow2-big"

        _ ->
          "bg-gradient-to-tl from-gray-400 to-gray-500"
      end
    else
      case last_move do
        {m1, m2} when i == m1 or i == m2 ->
          "bg-gradient-to-tl from-teal-600 to-teal-700 inset-shadow1 bl:inset-shadow1-big"

        _ ->
          "bg-gradient-to-tl from-teal-600 to-teal-700"
      end
    end
  end

  defp piece_color(color) do
    if color == :black do
      "bg-gradient-to-b from-gray-600 to-gray-900 bg-clip-text text-transparent"
    else
      "bg-gradient-to-b from-gray-100 to-gray-400 bg-clip-text text-transparent"
    end
  end

  defp border(i, selection, possible_moves) do
    case selectable?(i, selection, possible_moves) do
      0 ->
        ""

      1 ->
        "border-2 bl:border-4 border-blue-500 border-opacity-75 transform transition-transform bm:hover:scale-110"

      2 ->
        "border-2 bl:border-4 border-gray-200 border-opacity-50 transform transition-transform bm:hover:scale-110"
    end
  end
end
