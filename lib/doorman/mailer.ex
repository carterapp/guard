defmodule Doorman.Mailer do
  require Logger
  use Bamboo.Mailer, otp_app: :doorman
  import Bamboo.Email


  def create_mail(type, to, locale, user, meta \\ %{}) do
    module = Map.get(email_setup()[:templates], type)
    new_email(
              to: to,
              from: email_setup()[:default_sender],
              subject: apply(module, :subject, [locale, user, meta]),
              html_body: apply(module, :html_body, [locale, user, meta]),
              text_body: apply(module, :text_body, [locale, user, meta])
            )
  end
  
  def send_welcome_email(user) do
    Logger.debug "Sending welcome mail to #{user.requested_email}" 
    create_mail(:welcome, user.requested_email, user.locale, user)
    |> deliver_now
  end

  def send_confirm_email(user, token) do
    Logger.debug "Sending confirmation mail to #{user.requested_email}" 
    create_mail(:confirm, user.requested_email, user.locale, user, %{token: token})
    |> deliver_now
  end


  def send_reset_password_link(user, token) do
    Logger.debug "Sending reset mail to #{user.email}"
    create_mail(:reset, user.email, user.locale, user, %{token: token})
    |> deliver_now
 
  end

  def send_login_link(user, token) do
    Logger.debug "Sending login mail to #{user.email}"
    create_mail(:login, user.email, user.locale, user, %{token: token})
    |> deliver_now
  end

  defp email_setup do
    Application.get_env(:doorman, Doorman.Mailer)
  end

end

