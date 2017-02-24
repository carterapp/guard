defmodule Doorman.MailTestContent do
  require EEx


  EEx.function_from_file(:def, :subject,  Path.join(["#{:code.priv_dir(:doorman)}", "templates", "welcome.subject"]), [:locale, :user, :meta])
  EEx.function_from_file(:def, :html_body, Path.join(["#{:code.priv_dir(:doorman)}", "templates", "welcome.html"]), [:locale, :user, :meta])
  EEx.function_from_file(:def, :text_body, Path.join(["#{:code.priv_dir(:doorman)}", "templates", "welcome.text"]), [:locale, :user, :meta])
  
end
