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


  defp generate_response(resp, conn) do
    case resp do
      { :ok, claims } ->
        perms = Guard.Jwt.decode_permissions_from_claims(claims)
        user = Guardian.Plug.current_resource(conn)
        root_user = claims["usr"]
        extra = if root_user do
          %{root_user: root_user}
        else
          %{}
        end

        conn
        |> put_status(:ok)
        |> json(Map.merge(%{jwt: Guardian.Plug.current_token(conn), perms: perms, user: user}, extra))

      { :error, reason } ->
        conn
        |> put_status(:not_found)
        |> Controller.send_error(reason)
    end
 
  end

  def show(conn, _) do
    Authenticator.current_claims(conn) |> generate_response(conn)
  end


end

