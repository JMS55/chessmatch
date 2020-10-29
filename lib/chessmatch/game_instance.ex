defmodule Chessmatch.GameInstance do
  use GenServer

  def new() do
    {:ok, new_game_instance} =
      DynamicSupervisor.start_child(
        Chessmatch.GameInstanceSupervisor,
        Chessmatch.GameInstance
      )

    new_game_instance
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, {}}
  end
end
