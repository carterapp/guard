defmodule Guard.ApiKeyPipeline do
  @moduledoc false
  @default_realm "Key"

  @module_key :api_pipeline

  use Guardian.Plug.Pipeline,
    otp_app: :guard,
    error_handler: Guard.ErrorHandler,
    module: Guard.ApiKey,
    key: @module_key

  realm = Application.get_env(:guard, Guard.ApiKey)[:realm]
  realm = if realm, do: realm, else: @default_realm

  plug(Guardian.Plug.VerifyHeader, realm: realm, key: @module_key, module: Guard.ApiKey)
  plug(Guard.Plug.VerifyRequest, parameter: "_k", key: @module_key, realm: realm, module: Guard.ApiKey)
  plug(Guardian.Plug.LoadResource, allow_blank: true, key: @module_key, module: Guard.ApiKey)
end
