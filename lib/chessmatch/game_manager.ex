defmodule Chessmatch.GameManager do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_initial_info(role_id) do
    GenServer.call(__MODULE__, {:get_initial_info, role_id, self()})
  end

  def queue_up() do
    GenServer.cast(__MODULE__, {:queue_up, self()})
  end

  def move_piece(game_instance, move) do
    GenServer.cast(__MODULE__, {:move_piece, game_instance, move})
  end

  def cleanup_game(game_instance) do
    GenServer.cast(__MODULE__, {:cleanup_game, game_instance})
  end

  @impl true
  def init(:ok) do
    queue = []
    role_map = %{}
    game_extra_data = %{}
    subscribers = %{}

    {:ok, {queue, role_map, game_extra_data, subscribers}}
  end

  @impl true
  def handle_call(
        {:get_initial_info, role_id, caller_pid},
        _,
        {queue, role_map, game_extra_data, subscribers}
      ) do
    if Map.has_key?(role_map, role_id) do
      {role, game_instance} = Map.get(role_map, role_id)
      # Add caller to subscribers list
      game_subscribers = Map.get(subscribers, game_instance) ++ [caller_pid]
      subscribers = subscribers |> Map.put(game_instance, game_subscribers)

      # Return needed info
      {spectator_id, last_move} = Map.get(game_extra_data, game_instance)

      {:reply, {:ok, {role, spectator_id, game_instance, last_move}},
       {queue, role_map, game_extra_data, subscribers}}
    else
      {:reply, {:error, :game_not_found}, {queue, role_map, game_extra_data, subscribers}}
    end
  end

  @impl true
  def handle_cast({:queue_up, caller_pid}, {queue, role_map, game_extra_data, subscribers}) do
    queue = queue ++ [caller_pid]

    case queue do
      [p1, p2 | queue] ->
        # Create new binbo game
        {:ok, game_instance} =
          :binbo.new_server(%{
            :idle_timeout => 300_000,
            :onterminate =>
              {fn game_instance, _, _, _ ->
                 Chessmatch.GameManager.cleanup_game(game_instance)
               end, nil}
          })

        {:ok, _} = :binbo.new_game(game_instance)

        # Generate role_id's
        black_id = :rand.uniform(1_000_000)
        white_id = :rand.uniform(1_000_000)
        spectator_id = :rand.uniform(1_000_000)

        # Update state
        role_map =
          role_map
          |> Map.put(black_id, {:black, game_instance})
          |> Map.put(white_id, {:white, game_instance})
          |> Map.put(spectator_id, {:spectator, game_instance})

        game_extra_data = game_extra_data |> Map.put(game_instance, {spectator_id, nil})

        subscribers = subscribers |> Map.put(game_instance, [])

        # Redirect the caller to the new game
        ChessmatchWeb.LobbyLive.redirect_to_game(p1, black_id)
        ChessmatchWeb.LobbyLive.redirect_to_game(p2, white_id)

        {:noreply, {queue, role_map, game_extra_data, subscribers}}

      _ ->
        {:noreply, {queue, role_map, game_extra_data, subscribers}}
    end
  end

  @impl true
  def handle_cast(
        {:move_piece, game_instance, move},
        {queue, role_map, game_extra_data, subscribers}
      ) do
    # Update game_extra_data
    {spectator_id, _} = Map.get(game_extra_data, game_instance)
    game_extra_data = game_extra_data |> Map.put(game_instance, {spectator_id, move})

    # For each subscriber subscribed to game_instance, send them the new game_extra_data
    subscriber_list = Map.get(subscribers, game_instance)

    Enum.each(subscriber_list, fn subscriber ->
      ChessmatchWeb.GameLive.update_game_info(subscriber, {spectator_id, move})
    end)

    {:noreply, {queue, role_map, game_extra_data, subscribers}}
  end

  @impl true
  def handle_cast(
        {:cleanup_game, game_instance},
        {queue, role_map, game_extra_data, subscribers}
      ) do
    role_map = role_map |> Enum.filter(fn {_, {_, gi}} -> gi != game_instance end) |> Map.new()
    game_extra_data = game_extra_data |> Map.delete(game_instance)
    subscribers = subscribers |> Map.delete(game_instance)
    {:noreply, {queue, role_map, game_extra_data, subscribers}}
  end
end
