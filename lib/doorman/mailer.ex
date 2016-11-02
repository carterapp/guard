defmodule Doorman.Mailer do
  require Logger
  use Mailgun.Client,
     domain: Application.get_env(:doorman, :mailgun_domain),
     key: Application.get_env(:doorman, :mailgun_key),
     mode: Application.get_env(:doorman, :mailgun_mode),
     test_file_path: Application.get_env(:doorman, :mailgun_test_file_path)

  def send_welcome_email(user) do
    Logger.debug "Sending welcome mail to #{user.requested_email}" 
    send_email to: user.requested_email,
      from: email_setup.sender,
      subject: email_templates.welcome_subject(user),
      text: email_templates.welcome_body(user)
  end

  def send_reset_password_link(user, token) do
    Logger.debug "Sending reset mail to #{user.email}"
    send_email to: user.requested_email,
      from: email_setup.sender,
      subject: email_templates.reset_subject(user),
      text: email_templates.reset_body(user, %{"token" => token})
  end

  def send_login_link(user, token) do
    Logger.debug "Sending login mail to #{user.email}"
    send_email to: user.requested_email,
      from: email_setup.sender,
      subject: email_templates.login_subject(user),
      text: email_templates.login_body(user, %{"token" => token})
  end

  defp email_setup do
    Application.get_env(:doorman, :email_setup)
  end

  defp email_templates do
    Application.get_env(:doorman, :email_templates)
  end
end

