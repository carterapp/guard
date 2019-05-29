defmodule Guard.Sms do
  @moduledoc false
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
    module = Map.get(sms_templates(), type)
    locale = user.locale
    message = apply(module, :text_body, [locale, user, meta])
    send_message(user, message, callback)
  end

  def send_template_with_options(%User{} = user, type, meta, options, callback \\ nil) do
    module = Map.get(sms_templates(), type)
    locale = user.locale
    message = apply(module, :text_body, [locale, user, meta])
    options = options || %{}
    send_message(user, Map.put(options, :message, message), callback)
  end

  def send_confirm_mobile(user, pin, callback \\ nil) do
    module = Map.get(sms_templates(), :confirm)
    locale = user.locale
    message = apply(module, :text_body, [locale, user, %{pin: pin}])
    send_message(user.requested_mobile, message, callback)
  end

  def send_login_mobile(user, pin, callback \\ nil) do
    module = Map.get(sms_templates(), :login)
    locale = user.locale
    message = apply(module, :text_body, [locale, user, %{pin: pin}])
    send_message(user, message, callback)
  end

  defp sms_templates do
    # Look for templates email module if one has been defined for Guard.Sms
    Application.get_env(:guard, Guard.Sms)[:templates] ||
      Application.get_env(:guard, Guard.Mailer)[:templates]
  end
end
