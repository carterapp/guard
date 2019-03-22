defmodule Guard.Pusher do
  @moduledoc false
  alias Guard.User

  def send_user_message(user, message, callback \\ nil) do
    Guard.Pusher.Server.send_user_message(Guard.Pusher.Server, user, message, callback)
  end

  def status() do
    Guard.Pusher.Server.status(Guard.Pusher.Server)
  end

  def send_user_notification(user, title, body, callback \\ nil) do
    send_user_message(user, %{notification: %{body: body, title: title}}, callback)
  end

  def send_message(message, callback \\ nil) do
    Guard.Pusher.Server.send_message(Guard.Pusher.Server, message, callback)
  end

  def send_template(%User{} = user, type, meta, callback \\ nil) do
    module = Map.get(email_setup()[:templates], type)
    locale = user.locale
    title = apply(module, :subject, [locale, user, meta])
    message = apply(module, :text_body, [locale, user, meta])
    send_user_notification(user, title, message, callback)
  end

  # Templates are kept in the mailer module
  defp email_setup do
    Application.get_env(:guard, Guard.Mailer)
  end
end
