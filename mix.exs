defmodule Mazurka.Plug.Mixfile do
  use Mix.Project

  def project do
    [app: :mazurka_plug,
     version: "0.1.0",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:mazurka, ">= 1.0.0"},
     {:plug, ">= 0.0.0"},
     {:poison, "~> 2.2.0"}]
  end
end
