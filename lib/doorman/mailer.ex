defmodule Doorman.Mailer do
  require Logger
  use Bamboo.Mailer, otp_app: :doorman
  import Bamboo.Email


  def create_mail(type, to, locale, user, meta \\ %{}) do
    mail_conf = email_setup();
    if mail_conf != nil do
      module = Map.get(email_setup()[:templates], type)
      new_email(
                to: to,
                from: email_setup()[:default_sender],
                subject: apply(module, :subject, [locale, user, meta]),
                html_body: apply(module, :html_body, [locale, user, meta]),
                text_body: apply(module, :text_body, [locale, user, meta])
              )
    else
      {:error, :no_configuration} 
    end
  end


  def send_unverified_user_mail(user, type, meta \\ %{}) do
    Logger.debug "Sending #{type} mail to #{user.requested_email}" 
    create_mail(type, user.requested_email, user.locale, user, meta)
    |> deliver_now
  end

  def send_user_mail(user, type, meta \\ %{}) do
    email = user_email(user)
    Logger.debug "Sending #{type} mail to #{email}" 
    create_mail(type, email, user.locale, user, meta)
    |> deliver_now
  end
  
  def send_welcome_email(user, token) do
    Logger.debug "Sending welcome mail to #{user.requested_email}" 
    create_mail(:welcome, user.requested_email, user.locale, user, %{token: token})
    |> deliver_now
  end

  def send_confirm_email(user, token) do
    Logger.debug "Sending confirmation mail to #{user.requested_email}" 
    create_mail(:confirm, user.requested_email, user.locale, user, %{token: token})
    |> deliver_now
  end


  def send_reset_password_link(user, token) do
    email = user_email(user)
    Logger.debug "Sending reset mail to #{email}"
    create_mail(:reset, email, user.locale, user, %{token: token, user: user})
    |> deliver_now
  end

  def send_login_link(user, token) do
    email = user_email(user)
    Logger.debug "Sending login mail to #{email}"
    create_mail(:login, email, user.locale, user, %{token: token, user: user})
    |> deliver_now
  end

  def user_email(user) do
    user.email || user.requested_email  
  end

  defp email_setup do
    Application.get_env(:doorman, Doorman.Mailer)
  end

end

