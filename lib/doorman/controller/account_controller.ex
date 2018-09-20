defmodule Doorman.Controller.Account do
  use Phoenix.Controller
  alias Doorman.{Authenticator, User, Users}
  import Doorman.Controller, only: [send_error: 2, send_error: 3]

  plug Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"}

  def call(conn, opts) do
    try do
      super(conn, opts)
    rescue
      error -> send_error(conn, error, :internal_server_error)
    end
  end


  def update_attributes(conn, params) do
    user = Authenticator.authenticated_user!(conn)
    attrs = if user.attrs == nil, do: params, else: Map.merge(user.attrs, params)
    case Users.update_user(user, %{attrs: attrs}) do
      {:ok, user} -> 
        json conn, %{user: user}
      {:error, error, _} -> 
        send_error(conn, error)
    end
  end

  def update(conn, params) do
    updatable_fields = MapSet.new(["attrs", "requested_email", "username"])
    user = Authenticator.authenticated_user!(conn)
    changes = Enum.reduce(params, %{},
      fn ({k,v}, sum)->
        if MapSet.member?(updatable_fields, k) do 
          Map.put(sum,k,v)
        else 
          sum
        end
      end)

    case Users.update_user(user, changes) do
      {:ok, user} -> 
        json conn, %{user: user}
      {:error, error, _} -> 
        send_error(conn, error)
    end
  end

  def delete(conn, _) do
    user = Authenticator.authenticated_user!(conn)
    case Users.delete_user(user) do
      {:ok, user} -> 
      json conn, %{user: user}
      {:error, error, _} -> 
      send_error(conn, error)
    end
  end

end
