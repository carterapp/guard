defmodule Guard.ApiPipeline do
  @moduledoc false
  use Plug.Builder

  plug(Guard.ApiKeyPipeline)

  plug(Guard.JwtPipeline)
end
