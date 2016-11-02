defmodule Doorman.Repo do
  use Ecto.Repo, otp_app: :doorman


  def changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  def translate_error({msg, opts}) do
    Gettext.dngettext(Doorman.Gettext, "errors", msg, msg, opts[:count] || 1, opts)
  end

  def translate_error(msg) do
    Gettext.dgettext(Doorman.Gettext, "errors", msg)
  end


end
