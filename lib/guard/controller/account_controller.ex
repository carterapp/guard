defmodule Guard.Controller.Account do
  use Guard.Controller
  alias Guard.{Authenticator, Users}

  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})

  def update_attributes(conn, params) do
    user = Authenticator.authenticated_user!(conn)
    attrs = if user.attrs == nil, do: params, else: Map.merge(user.attrs, params)

    with {:ok, user} <- Users.update_user(user, %{attrs: attrs}) do
      json(conn, %{user: user})
    end
  end

  def update(conn, params) do
    updatable_fields = MapSet.new(["attrs", "requested_email", "username"])
    user = Authenticator.authenticated_user!(conn)

    changes =
      Enum.reduce(params, %{}, fn {k, v}, sum ->
        if MapSet.member?(updatable_fields, k) do
          Map.put(sum, k, v)
        else
          sum
        end
      end)

    with {:ok, user} <- Users.update_user(user, changes) do
      json(conn, %{user: user})
    end
  end

  def delete(conn, _) do
    user = Authenticator.authenticated_user!(conn)

    with {:ok, user} <- Users.delete_user(user) do
      json(conn, %{user: user})
    end
  end
end
