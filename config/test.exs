use Mix.Config

config :guardian, Guardian,
issuer: "Codenaut",
ttl: { 180, :days },
verify_issuer: true,
secret_key: "changethistosomeothersecret",
serializer: Doorman.GuardianSerializer,
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
hostname: "localhost",
port: 5433,
pool_size: 10,
pool: Ecto.Adapters.SQL.Sandbox

config :doorman, Doorman.Mailer,
adapter: Bamboo.TestAdapter,

default_sender: "biowatch@codenaut.com",
templates: %{
  welcome: Doorman.MailTestContent,
  login: Doorman.MailTestContent,
  reset: Doorman.MailTestContent,
  confirm: Doorman.MailTestContent
}

config :doorman, Doorman.Pusher,
token: "bad_token",
dry_run: true

config :plug, :validate_header_keys_during_test, true
