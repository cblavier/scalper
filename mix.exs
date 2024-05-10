defmodule Scalper.MixProject do
  use Mix.Project

  def project do
    [
      app: :scalper,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Scalper.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:google_api_sheets, "~> 0.31"},
      {:google_api_drive, "~> 0.21"},
      {:goth, "~> 1.2"},
      {:req, "~> 0.4.0"},
      {:floki, "~> 0.36.0"},
      {:charset_detect, "~> 0.1.1"},
      {:tz, "~> 0.26.5"}
    ]
  end
end
