defmodule Doorman.AuthApiPipeline do

  @claims %{typ: "access"}
  @default_realm "Bearer"

  use Guardian.Plug.Pipeline,
    otp_app: :Doorman,
    error_handler: Doorman.ErrorHandler,
    module: Doorman.Guardian

  realm = Application.get_env(:doorman, Doorman.Guardian)[:realm]
  realm = if realm, do: realm, else: @default_realm

  plug Guardian.Plug.VerifyHeader, claims: @claims, realm: realm
  plug Guardian.Plug.LoadResource, allow_blank: true
  plug Guardian.Plug.EnsureAuthenticated

end
