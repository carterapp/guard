defmodule Doorman.Controller.PasswordReset do
  use Phoenix.Controller
  alias Doorman.{Authenticator, User}
  import Doorman.Controller, only: [send_error: 2, send_error: 3]

  plug Guardian.Plug.EnsureAuthenticated

  def call(conn, opts) do
    try do
      super(conn, opts)
    rescue
      error -> send_error(conn, error, :internal_server_error)
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
