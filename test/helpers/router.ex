defmodule Doorman.Router do
  use Phoenix.Router
  require Doorman.Controller

  pipeline :api do
    plug :accepts, ["json"]
    plug Doorman.ApiPipeline
    plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Poison

    plug Plug.RequestId
    plug Plug.Logger
    plug Plug.MethodOverride
    plug Plug.Head
  end

  pipeline :authenticated do
    plug Doorman.AuthApiPipeline
  end

  pipeline :admin do
    plug Guardian.Permissions.Bitwise, ensure: %{admin: [:read, :write]}
  end

  scope "/doorman" do
    pipe_through :api
    Doorman.Controller.resources
  end
  
  scope "/jeeves" do
    pipe_through :api
    Doorman.Controller.admin_resources
  end

end
