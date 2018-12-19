use Mix.Config

config :guard, Guard.Guardian,
switch_user_permission: %{system: [:switch_user]},
permissions: %{
  admin: [:read, :write],
  user: [:read, :write],
  bundles: [:read, :write],
  system: [:read, :write, :switch_user],
}

config :guard, Guard.Jwt,
issuer: "Codenaut",
ttl: { 180, :days },
verify_issuer: true,
secret_key: "changethistosomeothersecret"

config :guard, Guard.Repo,
adapter: Ecto.Adapters.Postgres,
username: "doorman_test",
password: "doorman",
database: "doorman_test",
hostname: "localhost",
port: 5433,
pool_size: 10,
pool: Ecto.Adapters.SQL.Sandbox

config :guard, Guard.Mailer,
adapter: Bamboo.TestAdapter,

default_sender: "noone@codenaut.com",
templates: %{
  welcome: Guard.MailTestContent,
  login: Guard.MailTestContent,
  reset: Guard.MailTestContent,
  confirm: Guard.MailTestContent
}

config :guard, Guard.Pusher,
key: "bad_key",
dry_run: true

config :plug, :validate_header_keys_during_test, true

config :phoenix, :json_library, Jason

config :logger,
  backends: [:console],
  compile_time_purge_level: :debug
