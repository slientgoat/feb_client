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

    if Mix.env() == :dev do
      FebClient.set_feb_server("http://localhost:5000/api/multi_up")
    end

    IO.puts(
      "febclient info: #{inspect(%{feb_server_url: System.get_env("FEB_SERVER_URL"), poolboy_config: poolboy_config})}"
    )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FebClient.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
