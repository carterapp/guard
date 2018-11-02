defmodule Guard.Controller.ActiveSession do
  use Phoenix.Controller
  alias Guard.{Controller, Authenticator}
  require Logger
  import Guard.Controller, only: [send_error: 3]

  plug Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"}

  def call(conn, opts) do
    try do
      super(conn, opts)
    rescue
      error -> send_error(conn, error, :internal_server_error)
    end
  end


  def show(conn, _) do
    case Authenticator.current_claims(conn) do
      { :ok, _claims } ->
        user = Guardian.Plug.current_resource(conn)
        
        conn
        |> put_status(:ok)
        |> json(%{jwt: Guardian.Plug.current_token(conn), user: user})

      { :error, _reason } ->
        conn
        |> put_status(:not_found)
        |> Controller.send_error("not found")
    end
  end


end

