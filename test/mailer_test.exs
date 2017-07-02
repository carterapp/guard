defmodule Doorman.MailerTest do
  use ExUnit.Case
  

  test 'welcome_mail' do
    Doorman.Mailer.send_welcome_email(%{requested_email: "jalp@codenaut.com", locale: "en"}, "dummy")
  end

  
end
