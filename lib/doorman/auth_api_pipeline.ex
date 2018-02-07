defmodule Doorman.AuthApiPipeline do

  @claims %{typ: "access"}

  use Guardian.Plug.Pipeline,
    otp_app: :Doorman,
    error_handler: Doorman.ErrorHandler,
    module: Doorman.Guardian

    plug Guardian.Plug.VerifyHeader, claims: @claims, realm: "Bearer"
    plug Guardian.Plug.LoadResource, allow_blank: true
    plug Guardian.Plug.EnsureAuthenticated

end
