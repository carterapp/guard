defmodule Guard.Sms do
  alias Guard.User

  def send_message(user, message, callback \\ nil)

  def send_message(%User{} = user, message, callback) do
    send_message([user.mobile || user.requested_mobile], message, callback)
  end

  def send_message(recipients, message, callback) do
    Guard.Sms.Server.send_message(Guard.Sms.Server, recipients, message, callback)
  end

  def status() do
    Guard.Sms.Server.status(Guard.Sms.Server)
  end

  def send_template(%User{} = user, type, meta, callback \\ nil) do
    module = Map.get(email_setup()[:templates], type)
    locale = user.locale
    message = apply(module, :text_body, [locale, user, meta])
    send_message(user, message, callback)
  end

  def send_template_with_options(%User{} = user, type, meta, options = %{}, callback \\ nil) do
    module = Map.get(email_setup()[:templates], type)
    locale = user.locale
    message = apply(module, :text_body, [locale, user, meta])
    send_message(user, Map.put(options, :message, message), callback)
  end

  # Templates are kept in the mailer module
  defp email_setup do
    Application.get_env(:guard, Guard.Mailer)
  end
end
