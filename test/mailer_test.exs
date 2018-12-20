defmodule Guard.MailerTest do
  use ExUnit.Case

  test 'welcome_mail' do
    Guard.Mailer.send_welcome_email(
      %{requested_email: "jalp@codenaut.com", locale: "en"},
      "dummy",
      "pin"
    )
  end
end
