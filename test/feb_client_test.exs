defmodule FebClientTest do
  use ExUnit.Case
  doctest FebClient

  test "greets the world" do
    assert FebClient.hello() == :world
  end
end
