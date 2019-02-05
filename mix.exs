defmodule Guard.Mixfile do
  use Mix.Project

  def project do
    [
      app: :guard,
      version: "0.12.7",
      elixir: "~> 1.4 or ~> 1.5 or ~> 1.6 or ~> 1.7 or ~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: description(),
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "test/helpers"]
  defp elixirc_paths(_), do: ["lib"]

  defp application_list() do
    apps = [
      :logger,
      :guardian,
      :bamboo,
      :comeonin,
      :inets,
      :gettext,
      :plug_cowboy,
      :hackney,
      :tesla,
      :bcrypt_elixir,
      :jason
    ]

    if Mix.env() == :test do
      [:ecto, :ecto_sql, :postgrex] ++ apps
    else
      apps
    end
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {Guard, []}, applications: application_list()]
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
    [
      {:guardian, "~> 1.2.1"},
      {:phoenix, "~> 1.3 or ~> 1.4"},
      {:gettext, "~> 0.15 or ~> 0.16"},
      {:ecto, "~> 2.2 or ~> 3.0", optional: false},
      {:ecto_sql, "~> 3.0", optional: true},
      {:bamboo, "~> 1.1.0"},
      {:comeonin, "~> 4.1.1"},
      {:bcrypt_elixir, "~> 1.1.1"},
      {:tesla, "~> 1.2.1"},
      {:jason, "~> 1.1.2"},
      {:plug_cowboy, "~> 1.0 or ~> 2.0"},
      {:postgrex, "~> 0.13.0 or ~> 0.14.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false}
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
