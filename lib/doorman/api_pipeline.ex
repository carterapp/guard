defmodule Doorman.ApiPipeline do

  #Use :none to use no prefix before token
  @default_realm "Bearer"

  use Guardian.Plug.Pipeline,
    otp_app: :Doorman,
    error_handler: Doorman.ErrorHandler,
    module: Doorman.Guardian

  realm = Application.get_env(:doorman, Doorman.Guardian)[:realm]
  realm = if realm, do: realm, else: @default_realm

  plug Guardian.Plug.VerifyHeader, realm: realm
  plug Guardian.Plug.LoadResource, allow_blank: true

end
