defmodule Guard.Mixfile do
  use Mix.Project

  def project do
    [app: :guard,
     version: "0.7.1",
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     description: description(),
     deps: deps()]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/helpers"]
  defp elixirc_paths(_),     do: ["lib"]

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {Guard, []},
     applications: [:logger,
      :ecto, :guardian, :bamboo, :comeonin, :inets, :gettext, :plug_cowboy,
      :postgrex, :hackney, :tesla, :poison, :bcrypt_elixir, :jason]]
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
    [{:guardian, "~> 1.1.1"},
     {:phoenix, "~>1.3.2"},
     {:gettext, "~> 0.15.0"},
     {:ecto, "~> 2.2.10"},
     {:bamboo, "~> 1.1.0"},
     {:comeonin, "~> 4.1.1"},
     {:bcrypt_elixir, "~> 1.1.1"},
     {:tesla, "~> 1.2.0"},
     {:jason, "~> 1.0"},
     {:plug_cowboy, "~> 1.0"},
     {:poison, ">= 3.1.0"},
     {:postgrex, ">= 0.13.5", only: :test},
     {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description() do
    "Useful package for dealing with user authentication and signup"
  end
  
  defp package() do
    [
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/codenaut/guard"}
    ]
  end
end
