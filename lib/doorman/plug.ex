defmodule Doorman.Plug do
  use Plug.Builder 
  
  def ensure_headers(conn, opts) do
    conn 
    |> Guardian.Plug.VerifyHeader.call(opts)
    |> Guardian.Plug.LoadResource.call(opts)
  end

  def ensure_authenticated(conn, opts) do
    Guardian.Plug.EnsureAuthenticated.call conn, handler: Doorman.Controller
  end

  def ensure_authorized(conn, opts) do
    Guardian.Plug.EnsurePermissions.call conn, handler: Doorman.Controller
  end


end
