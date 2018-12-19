defmodule Guard.Controller.ActiveSession do
  use Phoenix.Controller
  alias Guard.{Controller, Authenticator, User, UserApiKey}
  import Guard.Controller, only: [send_error: 3]

  plug Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"}

  def call(conn, opts) do
    try do
      super(conn, opts)
    rescue
      error -> send_error(conn, error, :internal_server_error)
    end
  end



  defp decode_permissions(%User{}, claims) do
    Guard.Jwt.decode_permissions_from_claims(claims)
  end

  defp decode_permissions(%UserApiKey{}, claims) do
    Guard.Jwt.decode_permissions_from_claims(claims)
  end

  defp decode_permissions(_resource, _claims) do
    %{}
  end

  defp add_token(map, conn, %User{}) do
    map |> Map.put(:jwt, Guardian.Plug.current_token(conn))
  end
  defp add_token(map, conn, %UserApiKey{}) do
    map |> Map.put(:key, Guardian.Plug.current_token(conn))
  end
  defp add_token(map, _conn, _resource) do
    map
  end


  defp generate_response(resp, conn) do
    case resp do
      { :ok, claims } ->
        resource = Guardian.Plug.current_resource(conn)
        perms = decode_permissions(resource, claims)
        user = Guard.Authenticator.current_user(conn)
        root_user = claims["usr"]
        extra = if root_user do
          %{root_user: root_user}
        else
          %{}
        end
        conn
        |> put_status(:ok)
        |> json(Map.merge(%{perms: perms, user: user}, extra) |> add_token(conn, resource))

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

