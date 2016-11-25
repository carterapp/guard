defmodule Doorman.Controller.Session do
  use Phoenix.Controller
  import Doorman.Controller, only: [send_error: 2]

  defp process_session(conn, {:ok, user}) do
    case Guardian.encode_and_sign(user, :token, perms: user.perms || %{}) do
      {:ok, jwt, _full_claims} ->
        conn
        |> put_status(:created)
        |> json(%{jwt: jwt, user: user, perms: user.perms})
      {:error, error} ->
        send_error(conn, error)
    end
  end 

  defp process_session(conn, {:error, message}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: message})
  end


  def restore(conn, %{"token" => token}) do
    process_session conn, Doorman.Session.authenticate({:jwt, token})
  end  

  def create(conn, %{"session" => session_params}) do
    process_session conn, Doorman.Session.authenticate(session_params) 
  end

  def delete(conn, _) do
    case Guardian.Plug.claims(conn) do
      {:ok, claims} -> conn
      |> Guardian.Plug.current_token
      |> Guardian.revoke!(claims)
      _ -> nil
    end
    conn
    |> json(%{ok: true})
  end
end
