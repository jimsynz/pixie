defmodule Pixie.Mixfile do
  use Mix.Project

  def project do
    [app: :pixie,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [
      applications: [:logger, :cowboy, :plug],
      mod: {Pixie, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.0"},
      {:plug,   "~> 0.13"},
      {:erlfaye, github: "antoniogarrote/erlfaye", only: :fake_env},
      {:poison, "~> 1.4.0"}
    ]
  end
end
