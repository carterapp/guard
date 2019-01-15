defmodule Guard.JwtPipeline do
  # Use :none to use no prefix before token
  @default_realm "Bearer"

  use Guardian.Plug.Pipeline,
    otp_app: :guard,
    error_handler: Guard.ErrorHandler,
    module: Guard.Jwt

  realm = Application.get_env(:guard, Guard.Jwt)[:realm]
  realm = if realm, do: realm, else: @default_realm

  plug(Guardian.Plug.VerifyHeader, realm: realm, module: Guard.Jwt)
  plug(Guardian.Plug.VerifySession, realm: realm, module: Guard.Jwt)
  plug(Guardian.Plug.LoadResource, allow_blank: true, module: Guard.Jwt)
end
