defmodule FebClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: FebClientFinch},
      {Poolex, pool_id: :worker_pool, worker_module: FebClient.Worker, workers_count: 5}
    ]

    feb_server_url = Application.get_env(:feb_client, :api, System.get_env("FEB_SERVER_URL"))
    FebClient.set_api(feb_server_url)

    IO.puts("*** febclient application started: #{inspect(%{feb_server_url: feb_server_url})}")

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FebClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
