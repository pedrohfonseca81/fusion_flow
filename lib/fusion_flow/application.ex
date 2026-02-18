defmodule FusionFlow.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    try do
      Pythonx.uv_init("""
      [project]
      name = "fusion_flow"
      version = "0.1.0"
      requires-python = ">=3.11"
      dependencies = []
      """)
    rescue
      e ->
        require Logger
        Logger.warning("Pythonx init skipped: #{Exception.message(e)}")
    end

    children = [
      FusionFlowWeb.Telemetry,
      FusionFlow.Repo,
      {DNSCluster, query: Application.get_env(:fusion_flow, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:fusion_flow, Oban)},
      {Phoenix.PubSub, name: FusionFlow.PubSub},
      # Start a worker by calling: FusionFlow.Worker.start_link(arg)
      # {FusionFlow.Worker, arg},
      # Start to serve requests, typically the last entry
      FusionFlowWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FusionFlow.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FusionFlowWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
