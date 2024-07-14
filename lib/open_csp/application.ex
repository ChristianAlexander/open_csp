defmodule OpenCsp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OpenCspWeb.Telemetry,
      OpenCsp.Repo,
      {DNSCluster, query: Application.get_env(:open_csp, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: OpenCsp.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: OpenCsp.Finch},
      # Start a worker by calling: OpenCsp.Worker.start_link(arg)
      # {OpenCsp.Worker, arg},
      # Start to serve requests, typically the last entry
      OpenCspWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OpenCsp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OpenCspWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
