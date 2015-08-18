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
      applications: [:logger, :cowboy],
      mod: {Pixie, []}
    ]
  end

  defp deps do
    [
      {:cowboy,        "~> 1.0.0"},
      {:poison,        "~> 1.4.0"},
      {:secure_random, "~> 0.1"}
    ]
  end
end
