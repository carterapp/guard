defmodule Guard.Mailer do
  require Logger
  use Bamboo.Mailer, otp_app: :guard
  import Bamboo.Email

  def create_mail(type, to, locale, user, meta \\ %{}) do
    mail_conf = email_setup()

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

  def send_plain_mail(from, to, subject, body) do
    new_email(
      to: to,
      from: from,
      subject: subject,
      text_body: body
    )
    |> deliver_now()
  end

  def send_unverified_user_mail(user, type, meta \\ %{}) do
    Logger.debug(fn -> "Sending #{type} mail to #{user.requested_email}" end)

    type
    |> create_mail(user.requested_email, user.locale, user, meta)
    |> deliver_now
  end

  def send_user_mail(user, type, meta \\ %{}) do
    email = user_email(user)
    Logger.debug(fn -> "Sending #{type} mail to #{email}" end)

    type
    |> create_mail(email, user.locale, user, meta)
    |> deliver_now
  end

  def send_welcome_email(user, token, pin) do
    if user.requested_email != nil do
      Logger.debug(fn -> "Sending welcome mail to #{user.requested_email}" end)

      create_mail(:welcome, user.requested_email, user.locale, user, %{token: token, pin: pin})
      |> deliver_now
    end
  end

  def send_confirm_email(user, token) do
    Logger.debug(fn -> "Sending confirmation mail to #{user.requested_email}" end)

    create_mail(:confirm, user.requested_email, user.locale, user, %{token: token})
    |> deliver_now
  end

  def send_reset_password_link(user, token, pin) do
    email = user_email(user)
    Logger.debug(fn -> "Sending reset mail to #{email}" end)

    create_mail(:reset, email, user.locale, user, %{token: token, pin: pin})
    |> deliver_now
  end

  def send_login_link(user, token, pin) do
    email = user_email(user)
    Logger.debug(fn -> "Sending login mail to #{email}" end)

    create_mail(:login, email, user.locale, user, %{token: token, pin: pin})
    |> deliver_now
  end

  def user_email(user) do
    user.email || user.requested_email
  end

  defp email_setup do
    Application.get_env(:guard, Guard.Mailer)
  end
end
