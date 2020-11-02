defmodule Chessmatch.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Chessmatch.GameInstanceManager, name: Chessmatch.GameInstanceManager},
      # Start the Telemetry supervisor
      ChessmatchWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Chessmatch.PubSub},
      # Start the Endpoint (http/https)
      ChessmatchWeb.Endpoint
      # Start a worker by calling: Chessmatch.Worker.start_link(arg)
      # {Chessmatch.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chessmatch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ChessmatchWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
