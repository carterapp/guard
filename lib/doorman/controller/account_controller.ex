defmodule Doorman.Controller.Account do
  use Phoenix.Controller
  alias Doorman.{Authenticator, User}
  import Doorman.Controller, only: [send_error: 2]

  plug Guardian.Plug.EnsureAuthenticated, handler: Doorman.Controller


  def update(conn, params) do
    updatable_fields = MapSet.new(["attrs", "requested_email", "username"])
    user = Authenticator.current_user(conn)
    changes = Enum.reduce(params, %{},
      fn ({k,v}, sum)->
        if MapSet.member?(updatable_fields, k) do 
          sum = Map.put(sum,k,v)
        else 
          sum
        end
      end)
    case Authenticator.update_user(user, changes) do
      {:ok, user} -> 
        json conn, %{user: user}
      {:error, error, _} -> 
        send_error(conn, error)
    end
  end

  def delete(conn, _) do
    user = Authenticator.current_user(conn)
    case Authenticator.delete_user(user) do
      {:ok, user} -> 
      json conn, %{user: user}
      {:error, error, _} -> 
      send_error(conn, error)
    end
  end

  defp do_update_password(conn, user, new_password, new_password_confirmation) do
    case Authenticator.update_user(user, %{"password" => new_password, "password_confirmation" => new_password_confirmation}) do
          {:ok, _user} -> 
            json(conn, %{ok: true})
          {:error, error, _changeset} ->
            send_error(conn, error)
        end
  end


  def update_password(conn, %{"password" => password, "new_password" => new_password, "new_password_confirmation" => new_password_confirmation}) do
    user = Authenticator.current_user(conn)
    case User.check_password(user, password) do
      true ->
        do_update_password(conn, user, new_password, new_password_confirmation)
      false ->
        conn
        |> put_status(:precondition_failed)
        |> json(%{ok: false})

    end
  end

  def update_password(conn, %{"new_password" => new_password, "new_password_confirmation" => new_password_confirmation}) do
    case Authenticator.current_claim_type(conn) do
      "password_reset" ->
        user = Authenticator.current_user(conn)
        do_update_password(conn, user, new_password, new_password_confirmation)
      _ -> 
        conn
        |> put_status(:precondition_failed)
        |> json(%{ok: false})

    end
  end
  
  def update_password(conn, _) do
    conn
        |> put_status(:precondition_failed)
        |> json(%{ok: false})
  end

end
