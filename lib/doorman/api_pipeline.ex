defmodule Doorman.ApiPipeline do

  use Guardian.Plug.Pipeline,
    otp_app: :Doorman,
    error_handler: Doorman.ErrorHandler,
    module: Doorman.Guardian

    plug Guardian.Plug.VerifyHeader, realm: "Bearer"
    plug Guardian.Plug.LoadResource, allow_blank: true

end
