defmodule Doorman.Mixfile do
  use Mix.Project

  def project do
    [app: :doorman,
     version: "0.0.1",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/helpers"]
  defp elixirc_paths(_),     do: ["lib"]

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {Doorman, []},
     applications: [:logger,
      :ecto, :guardian, :bamboo, :comeonin,
      :postgrex]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:guardian, "~> 0.14.0"},
     {:phoenix, "~>1.2.1"},
     {:gettext, "~> 0.13.0"},
     {:ecto, "~> 2.1.1"},
     {:bamboo, "~> 0.7"},
     {:comeonin, "~> 3.0.0"},
     {:postgrex, ">= 0.13.0", only: :test}]
  end
end
