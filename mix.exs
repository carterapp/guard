defmodule Doorman.Mixfile do
  use Mix.Project

  def project do
    [app: :doorman,
     version: "0.0.1",
     elixir: "~> 1.4",
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
      :ecto, :guardian, :bamboo, :comeonin, :inets, :gettext,
      :postgrex, :hackney, :tesla, :poison, :bcrypt_elixir]]
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
    [{:guardian, "~> 1.0.1"},
     {:phoenix, "~>1.3.0"},
     {:gettext, "~> 0.14.0"},
     {:ecto, "~> 2.2.8"},
     {:bamboo, "~> 0.8"},
     {:comeonin, "~> 4.1.0"},
     {:bcrypt_elixir, "~> 1.0.6"},
     {:tesla, "~> 0.10.0"},
     {:poison, ">= 3.1.0"},
     {:postgrex, ">= 0.13.4", only: :test}]
  end
end
