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
  welcome: %{
    subject: &Doorman.MailTestContent.welcome_subject/3,
    html_body: &Doorman.MailTestContent.welcome_html_body/3,
    text_body: &Doorman.MailTestContent.welcome_text_body/3,
  }
}
