defmodule Doorman.MailTestContent do
  require EEx

  EEx.function_from_file(:def, :welcome_subject, "priv/templates/welcome.subject", [:locale, :user, :meta])
  EEx.function_from_file(:def, :welcome_html_body, "priv/templates/welcome.html", [:locale, :user, :meta])
  EEx.function_from_file(:def, :welcome_text_body, "priv/templates/welcome.text", [:locale, :user, :meta])
  
end
