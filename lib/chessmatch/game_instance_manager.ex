defmodule Chessmatch.GameInstanceManager do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def queue_up() do
    GenServer.cast(__MODULE__, {:queue_up, self()})
  end

  @impl true
  def init(:ok) do
    {:ok, {[], %{}}}
  end

  @impl true
  def handle_cast({:queue_up, caller_pid}, {queue, games}) do
    queue = queue ++ [caller_pid]

    case queue do
      [p1, p2 | queue] ->
        {:ok, new_game_instance} =
          DynamicSupervisor.start_child(
            Chessmatch.GameInstanceSupervisor,
            Chessmatch.GameInstance
          )

        black_id = :rand.uniform(1_000_000)
        white_id = :rand.uniform(1_000_000)
        spectator_id = :rand.uniform(1_000_000)

        games =
          games
          |> Map.put(black_id, {:black, new_game_instance})
          |> Map.put(white_id, {:white, new_game_instance})
          |> Map.put(spectator_id, {:spectator, new_game_instance})

        ChessmatchWeb.LobbyLive.redirect_to_game(p1, black_id)
        ChessmatchWeb.LobbyLive.redirect_to_game(p2, white_id)

        {:noreply, {queue, games}}

      _ ->
        {:noreply, {queue, games}}
    end
  end
end
