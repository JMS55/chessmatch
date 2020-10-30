defmodule Chessmatch.GameInstance do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def subscribe_to_changes(game_instance_pid) do
    GenServer.cast(game_instance_pid, {:subscribe_to_changes, self()})
  end

  def get_state(game_instance_pid) do
    GenServer.call(game_instance_pid, :get_state)
  end

  @impl true
  def init(:ok) do
    {:ok,
     {:white_turn,
      [
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
      ], []}}
  end

  @impl true
  def handle_cast({:subscribe_to_changes, caller_pid}, {game_state, board, subscribers}) do
    {:noreply, {game_state, board, [caller_pid] ++ subscribers}}
  end

  @impl true
  def handle_call(:get_state, _, {game_state, board, subscribers}) do
    {:reply, {game_state, board}, {game_state, board, subscribers}}
  end
end
