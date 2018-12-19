defmodule Guard.ApiPipeline do
  use Plug.Builder

  plug Guard.ApiKeyPipeline

  plug Guard.JwtPipeline


end
