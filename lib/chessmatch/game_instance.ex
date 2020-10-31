defmodule Chessmatch.GameInstance do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def subscribe_to_changes(game_instance_pid) do
    GenServer.cast(game_instance_pid, {:subscribe_to_changes, self()})
  end

  def get_state(game_instance_pid, role) do
    GenServer.call(game_instance_pid, {:get_state, role})
  end

  @impl true
  def init(:ok) do
    {:ok,
     {:white_turn,
      {
        {:rook, :black},
        {:knight, :black},
        {:bishop, :black},
        {:queen, :black},
        {:king, :black},
        {:bishop, :black},
        {:knight, :black},
        {:rook, :black},
        {:pawn, :black},
        {:pawn, :black},
        {:pawn, :black},
        {:pawn, :black},
        {:pawn, :black},
        {:pawn, :black},
        {:pawn, :black},
        {:pawn, :black},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:empty, nil},
        {:pawn, :white},
        {:pawn, :white},
        {:pawn, :white},
        {:pawn, :white},
        {:pawn, :white},
        {:pawn, :white},
        {:pawn, :white},
        {:pawn, :white},
        {:rook, :white},
        {:knight, :white},
        {:bishop, :white},
        {:queen, :white},
        {:king, :white},
        {:bishop, :white},
        {:knight, :white},
        {:rook, :white}
      }, []}}
  end

  @impl true
  def handle_cast({:subscribe_to_changes, caller_pid}, {game_status, board, subscribers}) do
    {:noreply, {game_status, board, [caller_pid | subscribers]}}
  end

  @impl true
  def handle_call({:get_state, role}, _, {game_status, board, subscribers}) do
    possible_moves = get_possible_moves(role, game_status, board)
    {:reply, {game_status, board, possible_moves}, {game_status, board, subscribers}}
  end

  defp get_possible_moves(role, game_status, board) do
    if (role == :black and game_status == :black_turn) or
         (role == :white and game_status == :white_turn) do
      board
      |> Tuple.to_list()
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {{piece, color}, i}, possible_moves ->
        case piece do
          :pawn when color == role ->
            {capture_left, capture_right, move_forward} =
              if role == :white do
                {offset_1d_index(i, -1, 1), offset_1d_index(i, 1, 1), offset_1d_index(i, 0, 1)}
              else
                {offset_1d_index(i, -1, -1), offset_1d_index(i, 1, -1), offset_1d_index(i, 0, -1)}
              end

            moves =
              []
              |> add_if(
                capture_left,
                capture_left != nil and elem(elem(board, capture_left), 1) != role
              )
              |> add_if(
                capture_right,
                capture_right != nil and elem(elem(board, capture_right), 1) != role
              )
              |> add_if(
                move_forward,
                move_forward != nil and elem(elem(board, move_forward), 0) == :empty
              )

            if not Enum.empty?(moves) do
              Map.put(possible_moves, i, moves)
            else
              possible_moves
            end

          :rook when color == role ->
            possible_moves

          :knight when color == role ->
            {a, b, c, d, e, f, g, h} =
              {offset_1d_index(i, 1, 2), offset_1d_index(i, -1, 2), offset_1d_index(i, 1, -2),
               offset_1d_index(i, -1, -2), offset_1d_index(i, 2, 1), offset_1d_index(i, 2, -1),
               offset_1d_index(i, -2, 1), offset_1d_index(i, -2, -1)}

            moves =
              []
              |> add_if(
                a,
                a != nil and elem(elem(board, a), 1) != role
              )
              |> add_if(
                b,
                b != nil and elem(elem(board, b), 1) != role
              )
              |> add_if(
                c,
                c != nil and elem(elem(board, c), 1) != role
              )
              |> add_if(
                d,
                d != nil and elem(elem(board, d), 1) != role
              )
              |> add_if(
                e,
                e != nil and elem(elem(board, e), 1) != role
              )
              |> add_if(
                f,
                f != nil and elem(elem(board, f), 1) != role
              )
              |> add_if(
                g,
                g != nil and elem(elem(board, g), 1) != role
              )
              |> add_if(
                h,
                h != nil and elem(elem(board, h), 1) != role
              )

            if not Enum.empty?(moves) do
              Map.put(possible_moves, i, moves)
            else
              possible_moves
            end

          :bishop when color == role ->
            possible_moves

          :queen when color == role ->
            possible_moves

          :king when color == role ->
            {a, b, c, d, e, f, g, h} =
              {offset_1d_index(i, 1, 0), offset_1d_index(i, -1, 0), offset_1d_index(i, 0, -1),
               offset_1d_index(i, 0, 1), offset_1d_index(i, 1, 1), offset_1d_index(i, 1, -1),
               offset_1d_index(i, -1, 1), offset_1d_index(i, -1, -1)}

            moves =
              []
              |> add_if(
                a,
                a != nil and elem(elem(board, a), 1) != role
              )
              |> add_if(
                b,
                b != nil and elem(elem(board, b), 1) != role
              )
              |> add_if(
                c,
                c != nil and elem(elem(board, c), 1) != role
              )
              |> add_if(
                d,
                d != nil and elem(elem(board, d), 1) != role
              )
              |> add_if(
                e,
                e != nil and elem(elem(board, e), 1) != role
              )
              |> add_if(
                f,
                f != nil and elem(elem(board, f), 1) != role
              )
              |> add_if(
                g,
                g != nil and elem(elem(board, g), 1) != role
              )
              |> add_if(
                h,
                h != nil and elem(elem(board, h), 1) != role
              )

            if not Enum.empty?(moves) do
              Map.put(possible_moves, i, moves)
            else
              possible_moves
            end

          _ ->
            possible_moves
        end
      end)
    else
      %{}
    end
  end

  defp offset_1d_index(i, x_offset, y_offset) do
    x = rem(i, 8) + x_offset
    y = div(i, 8) - y_offset

    if x < 0 or x > 7 or y < 0 or y > 7 do
      nil
    else
      x + y * 8
    end
  end

  defp add_if(list, item, condition) do
    if condition do
      [item | list]
    else
      list
    end
  end
end
