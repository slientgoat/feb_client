defmodule FebClient.Worker do
  use GenServer
  import FebClient.Logger

  @per_push_limit 1000
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def init([]) do
    submit_inteval = Enum.random(1..5) * 1000
    Process.put(:submit_inteval, submit_inteval)

    debug("started", inspect(%{submit_inteval: submit_inteval}))

    send(self(), :push_reports)
    {:ok, []}
  end

  @impl true
  def handle_cast({:submit, report}, reports) do
    debug("submit to feb client cache.", inspect(report))
    {:noreply, [report | reports]}
  end

  @impl true
  def handle_info(:push_reports, reports) do
    inteval = Process.get(:submit_inteval)

    feb_server_url = FebClient.get_api()

    with true <- (feb_server_url != "" and feb_server_url != nil) || :unset_env,
         true <- valid_url?(feb_server_url) || :invalid_server_url,
         true <- reports != [] || :ignore,
         {push_list, rest_reports} <- Enum.split(reports, @per_push_limit),
         "ok" <- push(push_list, feb_server_url) do
      debug("push  reports to feb server.", %{num: length(push_list)})
      Process.send_after(self(), :push_reports, inteval)
      {:noreply, rest_reports}
    else
      :unset_env ->
        Process.send_after(self(), :push_reports, inteval)
        {:noreply, []}

      :ignore ->
        Process.send_after(self(), :push_reports, inteval)
        {:noreply, []}

      :econnrefused ->
        Process.send_after(self(), :push_reports, inteval)
        {:noreply, reports}

      reason ->
        error("push to feb server fail for reason", inspect(reason))
        Process.send_after(self(), :push_reports, inteval)
        {:noreply, []}
    end
  end

  defp push(push_list, feb_server_url) do
    feb_server_url
    |> HTTPoison.post(
      %{body: Jason.encode!(push_list)} |> Jason.encode!(),
      ["Content-Type": "application/json"],
      recv_timeout: 5000
    )
    |> case do
      {:ok, %HTTPoison.Response{status_code: 200, body: "ok"}} ->
        "ok"

      {:ok, %HTTPoison.Response{status_code: 200, body: "unhandle error"}} ->
        :unhandle_error

      {:ok, %HTTPoison.Response{status_code: 400, body: body}} ->
        debug("bad request", inspect(%{push_list: push_list, reason: body}))
        :bad_request

      {:ok, %HTTPoison.Response{status_code: 404, body: body}} ->
        debug("not found", inspect(%{push_list: push_list, reason: body}))
        :not_found

      {:ok, %HTTPoison.Response{status_code: 500}} ->
        :server_error

      {:error, %HTTPoison.Error{reason: :econnrefused}} ->
        debug("econnrefused records will push at the next time", %{num: length(push_list)})

        :econnrefused

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:unkonwn, reason}
    end
  end

  def valid_url?(url) do
    uri = URI.parse(url)
    uri.scheme != nil && uri.host != ""
  end
end
