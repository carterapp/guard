defmodule Doorman.MailTestContent do
  require EEx


  EEx.function_from_file(:def, :welcome_subject,  Path.join(["#{:code.priv_dir(:doorman)}", "templates", "welcome.subject"]), [:locale, :user, :meta])
  EEx.function_from_file(:def, :welcome_html_body, Path.join(["#{:code.priv_dir(:doorman)}", "templates", "welcome.html"]), [:locale, :user, :meta])
  EEx.function_from_file(:def, :welcome_text_body, Path.join(["#{:code.priv_dir(:doorman)}", "templates", "welcome.text"]), [:locale, :user, :meta])
  
end
