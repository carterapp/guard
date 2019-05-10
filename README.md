# Guard

[![Build Status](https://travis-ci.com/Codenaut/guard.svg?branch=master)](https://travis-ci.com/Codenaut/guard)

Collection of common functionality for user handling.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add guard to your list of dependencies in `mix.exs`:

        def deps do
          [{:guard, "~> 0.14.4"}]
        end

  2. Ensure guard is started before your application:

        def application do
          [applications: [:guard]]
        end


## Notes

If you're having trouble having Guardian.Permission.Bitwise picking up your
newly defined permissions - try doing a `mix dep.clean guardian`.

Sometimes a `rm -rf _build is needed`
