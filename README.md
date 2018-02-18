# Doorman

Collection of common functionality for user handling.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add doorman to your list of dependencies in `mix.exs`:

        def deps do
          [{:doorman, "~> 0.0.1"}]
        end

  2. Ensure doorman is started before your application:

        def application do
          [applications: [:doorman]]
        end


## Notes

If you're having trouble having Guardian.Permission.Bitwise picking up your
newly defined permissions - try doing a `mix dep.clean guardian`.
