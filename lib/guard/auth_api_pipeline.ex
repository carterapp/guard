defmodule Guard.AuthApiPipeline do

  @claims %{typ: "access"}
  @default_realm "Bearer"

  use Guardian.Plug.Pipeline,
    otp_app: :Guard,
    error_handler: Guard.ErrorHandler,
    module: Guard.Guardian

  realm = Application.get_env(:guard, Guard.Guardian)[:realm]
  realm = if realm, do: realm, else: @default_realm

  plug Guardian.Plug.VerifyHeader, claims: @claims, realm: realm
  plug Guardian.Plug.LoadResource, allow_blank: true
  plug Guardian.Plug.EnsureAuthenticated

end
