defmodule Guard.Controller.Account do
  use Phoenix.Controller
  alias Guard.{Authenticator, Users}
  require Logger

  import Guard.Controller, only: [send_error: 2]

  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})

  def call(conn, opts) do
    try do
      super(conn, opts)
    rescue
      error -> send_error(conn, error)
    end
  end

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
    Logger.info("asdlfjasdlfajsdlkfjasldf")

    with {:ok, user} <- Users.delete_user(user) do
      json(conn, %{user: user})
    end
  end
end
