defmodule Guard.Controller.KeyController do
  use Phoenix.Controller
  alias Guard.{Authenticator, Users}
  import Guard.Controller, only: [send_error: 3]

  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})

  def call(conn, opts) do
    try do
      super(conn, opts)
    rescue
      error -> send_error(conn, error, :internal_server_error)
    end
  end

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
