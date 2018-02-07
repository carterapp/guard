use Mix.Config

config :doorman, Doorman.Guardian,
issuer: "Codenaut",
ttl: { 180, :days },
verify_issuer: true,
secret_key: "changethistosomeothersecret",
permissions: %{
  user: [:read, :write],
  bundles: [:read, :write],
  system: [:read, :write]
}

config :doorman, Doorman.Repo,
adapter: Ecto.Adapters.Postgres,
username: "doorman_test",
password: "doorman",
database: "doorman_test",
hostname: "docker",
port: 5433,
pool_size: 10,
pool: Ecto.Adapters.SQL.Sandbox

