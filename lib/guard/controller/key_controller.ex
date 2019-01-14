defmodule Guard.Controller.KeyController do
  use Guard.Controller
  alias Guard.{Authenticator, Users}

  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})

  def create_key(conn, params) do
    permissions = Map.get(params, "permissions", %{})

    with {:ok, key} <- Users.create_api_key(Authenticator.authenticated_user!(conn), permissions) do
      conn |> json(key)
    end
  end

  def list_keys(conn, _) do
    keys = Users.list_api_keys(Authenticator.authenticated_user!(conn))

    conn
    |> json(keys)
  end

  def revoke_key(conn, %{"key" => key}) do
    response = Guard.ApiKey.revoke(key)

    with {:ok, _} <- response do
      conn |> json(%{key: key})
    else
      _any ->
        conn |> put_status(:not_found)
    end
  end
end
