defmodule FebClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :feb_client,
      version: "0.2.7",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {FebClient.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:poolex, "~> 0.6.0"}, {:finch, "~> 0.15"}, {:jason, "~> 1.2"}]
  end
end
