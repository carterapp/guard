defmodule Guard.Router do
  use Phoenix.Router
  require Guard.Controller

  pipeline :api do
    plug :accepts, ["json"]
    plug Guard.ApiPipeline
    plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Poison

    plug Plug.RequestId
    plug Plug.Logger
    plug Plug.MethodOverride
    plug Plug.Head
  end

  pipeline :authenticated do
    plug Guard.AuthApiPipeline
  end

  pipeline :admin do
    plug Guardian.Permissions.Bitwise, ensure: %{system: [:read, :write]}
  end

  scope "/guard" do
    pipe_through :api
    Guard.Controller.resources
  end
  
  scope "/jeeves" do
    pipe_through :api
    pipe_through :admin
    Guard.Controller.admin_resources
  end

end
