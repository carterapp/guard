defmodule Guard.Repo do
  if Application.get_env(:guard,  Guard.Repo) do
    use Ecto.Repo, otp_app: :guard, adapter: Ecto.Adapters.Postgres
  else
    use Guard.ExternalRepo
  end


  def changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  def translate_error({msg, opts}) do
    Gettext.dngettext(Guard.Gettext, "errors", msg, msg, opts[:count] || 1, opts)
  end

  def translate_error(msg) do
    Gettext.dgettext(Guard.Gettext, "errors", msg)
  end


end
