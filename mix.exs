defmodule JraCrawler.MixProject do
  use Mix.Project

  def project do
    [
      app: :jra_crawler,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:floki, "~> 0.24.0"},
      {:httpoison, "~> 1.6"},
      {:elixir_mbcs, github: "woxtu/elixir-mbcs", tag: "0.1.3"},
      {:poison, "~> 4.0.0"}
    ]
  end
end
