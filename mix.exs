defmodule Mazurka.Plug.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mazurka_plug,
      description: "Plug integration for Mazurka",
      version: "0.1.7",
      elixir: "~> 1.0",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:fugue, ">= 0.1.0"},
      {:html_builder, github: "simplecastapps/html_builder"},
      {:mazurka, github: "simplecastapps/mazurka"},
      {:plug, ">= 0.0.0"},
      {:poison, ">= 2.2.0"}
    ]
  end
end
