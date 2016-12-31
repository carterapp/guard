defmodule Doorman.Mailer do
  require Logger
  use Bamboo.Mailer, otp_app: :doorman
  import Bamboo.Email


  def create_mail(type, to, locale, meta) do
    template = Map.get(email_setup[:templates], type)
    new_email(
              to: to,
              from: email_setup[:default_sender],
              subject: template.subject.(locale, meta),
              html_body: template.html_body.(locale, meta),
              text_body: template.text_body.(locale, meta)
            )
  end
  
  def send_welcome_email(user) do
    Logger.debug "Sending welcome mail to #{user.requested_email}" 
    create_mail(:welcome, user.requested_email, user.locale, user)
    |> deliver_now
  end

  def send_reset_password_link(user, token) do
    Logger.debug "Sending reset mail to #{user.email}"
  end

  def send_login_link(user, token) do
    Logger.debug "Sending login mail to #{user.email}"
  end

  defp email_setup do
    Application.get_env(:doorman, Doorman.Mailer)
  end

end

