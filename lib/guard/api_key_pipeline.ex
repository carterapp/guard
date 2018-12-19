defmodule Guard.ApiKeyPipeline do

  @default_realm "Key"

  use Guardian.Plug.Pipeline,
    otp_app: :guard,
    error_handler: Guard.ErrorHandler,
    module: Guard.ApiKey

  realm = Application.get_env(:guard, Guard.ApiKey)[:realm]
  realm = if realm, do: realm, else: @default_realm

  plug Guardian.Plug.VerifyHeader, realm: realm
  plug Guardian.Plug.LoadResource, allow_blank: true

end
