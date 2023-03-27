defmodule FebClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp poolboy_config do
    [
      name: {:local, :worker},
      worker_module: FebClient.Worker,
      size: 5,
      strategy: :fifo,
      max_overflow: 5
    ]
  end

  @impl true
  def start(_type, _args) do
    poolboy_config = poolboy_config()

    children = [
      :poolboy.child_spec(
        :worker,
        Application.get_env(:feb_client, :poolboy_config, poolboy_config),
        []
      )
    ]

    feb_server_url = Application.get_env(:feb_client, :api, System.get_env("FEB_SERVER_URL"))
    FebClient.set_api(feb_server_url)

    IO.puts(
      "*** febclient application started: #{inspect(%{poolboy_config: poolboy_config, feb_server_url: feb_server_url})}"
    )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FebClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
