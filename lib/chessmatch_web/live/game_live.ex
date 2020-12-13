defmodule ChessmatchWeb.GameLive do
  use ChessmatchWeb, :live_view

  @impl true
  def mount(%{"role_id" => role_id}, _session, socket) do
    with {role_id, ""} <- Integer.parse(role_id),
         {:ok, {role, spectator_id, game_instance, last_move}} <-
           Chessmatch.GameManager.get_initial_info(role_id) do
      spectator_link = Routes.live_url(socket, ChessmatchWeb.GameLive, spectator_id)

      socket =
        socket
        |> assign(:role, role)
        |> assign(:spectator_link, spectator_link)
        |> assign(:game_instance, game_instance)
        |> assign(:last_move, last_move)
        |> assign(:selection, {nil, nil})
        |> assign(:forfeit_dialog_open, false)
        |> update_state()

      {:ok, socket}
    else
      _ -> Phoenix.Router.MalformedURIError
    end
  end

  def update_game_info(pid, {_, last_move}) do
    Process.send(pid, {:update_game_info, last_move}, [])
  end

  @impl true
  def handle_info({:update_game_info, last_move}, socket) do
    socket = socket |> assign(:last_move, last_move) |> update_state()
    {:noreply, socket}
  end

  defp update_state(socket) do
    game_instance = socket.assigns.game_instance

    {:ok, game_status} = :binbo.game_status(game_instance)
    {:ok, side_to_move} = :binbo.side_to_move(game_instance)

    game_message = Chessmatch.BinboHelper.parse_game_status(game_status, side_to_move)
    board = Chessmatch.BinboHelper.get_board(socket.assigns.role, game_instance)

    possible_moves =
      if socket.assigns.role == side_to_move and game_status == :continue do
        Chessmatch.BinboHelper.get_possible_moves(game_instance)
      else
        %{}
      end

    socket
    |> assign(:game_message, game_message)
    |> assign(:board, board)
    |> assign(:possible_moves, possible_moves)
  end

  @impl true
  def handle_event("select_piece", %{"selection" => selection}, socket) do
    {selection, _} = Integer.parse(selection)

    selected_other_piece = Map.has_key?(socket.assigns.possible_moves, selection)

    case socket.assigns.selection do
      {nil, nil} ->
        {:noreply, assign(socket, :selection, {selection, nil})}

      {from, nil} when from == selection ->
        {:noreply, assign(socket, :selection, {nil, nil})}

      {_from, nil} when selected_other_piece ->
        {:noreply, assign(socket, :selection, {selection, nil})}

      {from, nil} ->
        game_instance = socket.assigns.game_instance
        :binbo.index_move(game_instance, from, selection)
        Chessmatch.GameManager.move_piece(game_instance, {from, selection})

        socket = socket |> assign(:selection, {nil, nil})
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_forfeit_dialog", _, socket) do
    socket = assign(socket, :forfeit_dialog_open, not socket.assigns.forfeit_dialog_open)
    {:noreply, socket}
  end

  @impl true
  def handle_event("forfeit_match", _, socket) do
    socket = assign(socket, :forfeit_dialog_open, not socket.assigns.forfeit_dialog_open)

    winner =
      if socket.assigns.role == :black do
        :white
      else
        :black
      end

    :binbo.set_game_winner(socket.assigns.game_instance, winner, :forfeit)
    Chessmatch.GameManager.move_piece(socket.assigns.game_instance, socket.assigns.last_move)

    {:noreply, update_state(socket)}
  end
end
