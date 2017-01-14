defmodule Mazurka.Plug.Mixfile do
  use Mix.Project

  def project do
    [app: :mazurka_plug,
     description: "Plug integration for Mazurka",
     version: "0.1.4",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:fugue, ">= 0.1.0"},
     {:html_builder, "~> 0.1"},
     {:mazurka, ">= 1.0.0"},
     {:plug, ">= 0.0.0"},
     {:poison, ">= 2.2.0"},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end

  defp package do
    [files: ["lib", "mix.exs", "README*"],
     maintainers: ["Cameron Bytheway"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/exstruct/mazurka_plug"}]
  end
end
