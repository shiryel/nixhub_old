defmodule Core.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CoreWeb.Telemetry,
      # Start the Ecto repository
      Core.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Core.PubSub},
      # Start Finch
      {Finch, name: Core.Finch},
      # Start the Endpoint (http/https)
      CoreWeb.Endpoint,
      # Start Cron-like Scheduler
      Core.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
