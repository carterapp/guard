defmodule Doorman.Mailer do
  require Logger

  def send_welcome_email(user) do
    Logger.debug "Sending welcome mail to #{user.requested_email}" 
  end

  def send_reset_password_link(user, token) do
    Logger.debug "Sending reset mail to #{user.email}"
  end

  def send_login_link(user, token) do
    Logger.debug "Sending login mail to #{user.email}"
  end

  defp email_setup do
    Application.get_env(:doorman, :email_setup)
  end

  defp email_templates do
    Application.get_env(:doorman, :email_templates)
  end
end

