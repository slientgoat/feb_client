defmodule FebClient do
  @timeout 5000
  def set_feb_server(url) do
    System.put_env("FEB_SERVER_URL", url)
  end

  def disable() do
    System.put_env("FEB_SERVER_URL", nil)
  end

  def call(msg) do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.call(pid, msg) end,
      @timeout
    )
  end

  def cast(msg) do
    :poolboy.transaction(
      :worker,
      fn pid -> GenServer.cast(pid, msg) end,
      @timeout
    )
  end

  def submit(report) do
    cast({:submit, report})
  end

  def test_login(i) do
    %{
      "action" => "login",
      "zone" => "zone1",
      "os" => "pc",
      "type" => "google play",
      "role_id" => 100_000 + i,
      "login_at" => i
    }
    |> submit()
  end

  def test_register(i) do
    %{
      "action" => "register",
      "zone" => "zone1",
      "os" => "pc",
      "type" => "google play",
      "role_id" => 100_000 + i,
      "create_at" => i
    }
    |> submit()
  end

  def t(n) do
    Enum.to_list(1..n)
    |> Enum.each(&test_login/1)

    Enum.to_list(1..n)
    |> Enum.each(&test_register/1)
  end
end
