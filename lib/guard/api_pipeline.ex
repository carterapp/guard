defmodule Guard.ApiPipeline do

  #Use :none to use no prefix before token
  @default_realm "Bearer"

  use Guardian.Plug.Pipeline,
    otp_app: :Guard,
    error_handler: Guard.ErrorHandler,
    module: Guard.Guardian

  realm = Application.get_env(:guard, Guard.Guardian)[:realm]
  realm = if realm, do: realm, else: @default_realm

  plug Guardian.Plug.VerifyHeader, realm: realm
  plug Guardian.Plug.LoadResource, allow_blank: true

end
