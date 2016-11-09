defmodule Doorman.Plug do
  use Plug.Builder 
  
  def ensure_headers(conn, _opts) do
    conn
  end

  def ensure_authenticated(conn, _opts) do
    conn
  end

  def ensure_authorized(conn, opts) do
    conn
  end


end
