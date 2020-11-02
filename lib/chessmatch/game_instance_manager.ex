defmodule Chessmatch.GameInstanceManager do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def queue_up() do
    GenServer.cast(__MODULE__, {:queue_up, self()})
  end

  def get_game_info(game_id) do
    GenServer.call(__MODULE__, {:get_game_info, game_id})
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
        {:ok, game_instance} = :binbo.new_server()
        {:ok, _} = :binbo.new_game(game_instance)

        black_id = :rand.uniform(1_000_000)
        white_id = :rand.uniform(1_000_000)
        spectator_id = :rand.uniform(1_000_000)

        games =
          games
          |> Map.put(black_id, {:black, game_instance})
          |> Map.put(white_id, {:white, game_instance})
          |> Map.put(spectator_id, {:spectator, game_instance})

        ChessmatchWeb.LobbyLive.redirect_to_game(p1, black_id)
        ChessmatchWeb.LobbyLive.redirect_to_game(p2, white_id)

        {:noreply, {queue, games}}

      _ ->
        {:noreply, {queue, games}}
    end
  end

  @impl true
  def handle_call({:get_game_info, game_id}, _, {queue, games}) do
    game_info = games[game_id]

    if game_info != nil do
      {:reply, {:ok, game_info}, {queue, games}}
    else
      {:reply, {:error, :game_not_found}, {queue, games}}
    end
  end
end
