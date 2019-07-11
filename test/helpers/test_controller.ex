defmodule(Guard.Test.Controller) do
  @moduledoc false
  use Guard.Controller

  def context_test(conn, _) do
    user = Guard.Authenticator.authenticated_user!(conn)

    conn
    |> json(user.context)
  end

  def permission_test(conn, _) do
    permissions = Guard.Authenticator.current_permissions(conn)

    is_admin = Guard.Authenticator.all_permissions?(conn, %{admin: [:read], system: [:read]})
    is_user = Guard.Authenticator.any_permissions?(conn, %{admin: [:read], user: [:read]})

    conn
    |> json(%{permissions: permissions, is_admin: is_admin, is_user: is_user})
  end
end
