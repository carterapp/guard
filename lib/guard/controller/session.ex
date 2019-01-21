defmodule Guard.Controller.Session do
  use Guard.Controller
  alias Guard.{Session, Authenticator, User, UserApiKey}

  @claim_whitelist ["usr"]

  defp process_session(conn, {:ok, %User{} = user}) do
    process_session(conn, {:ok, user, %{}})
  end

  defp process_session(conn, {:ok, %User{} = user, claims}) do
    conn
    |> Authenticator.sign_in(user, claims |> Map.take(@claim_whitelist))
    |> Session.current_session()
    |> case do
      {:ok, session} ->
        conn
        |> put_status(:created)
        |> json(session)

      {:error, error} ->
        send_error(conn, error)
    end
  end

  defp process_session(conn, {:error, message}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: message})
  end

  defp process_session(conn, {:ok, jwt, claims}) do
    case Guard.Jwt.resource_from_claims(claims) do
      {:ok, user} ->
        root_user = claims["usr"]

        extra =
          if root_user do
            %{root_user: root_user}
          else
            %{}
          end

        conn
        |> put_status(:created)
        |> json(
          Map.merge(%{jwt: jwt, user: user, perms: user.perms, root_user: root_user}, extra)
        )

      {:error, error} ->
        send_error(conn, error)
    end
  end

  def restore(conn, %{"token" => token}) do
    process_session(conn, Session.authenticate({:jwt, token}))
  end

  def create(conn, %{"session" => session_params}) do
    process_session(conn, Session.authenticate(session_params))
  end

  def create(conn, params) do
    process_session(conn, Session.authenticate(conn, params))
  end

  def delete(conn, _) do
    case Guardian.Plug.current_resource(conn) do
      %User{} ->
        conn
        |> Guard.Jwt.Plug.sign_out()

      %UserApiKey{} ->
        conn
        |> Guardian.Plug.current_token()
        |> Guard.ApiKey.revoke()

      _any ->
        nil
    end

    conn
    |> json(%{ok: true})
  end

  def switch_user(conn, %{"id" => id}) do
    user = Guard.Users.get!(id)
    process_session(conn, Authenticator.switch_user(conn, user))
  end

  def switch_user(conn, %{"username" => username}) do
    user = Guard.Users.get_by_username!(username)
    process_session(conn, Authenticator.switch_user(conn, user))
  end

  def switch_user(conn, %{"mobile" => mobile}) do
    user = Guard.Users.get_by_mobile!(mobile)
    process_session(conn, Authenticator.switch_user(conn, user))
  end

  def switch_user(conn, %{"email" => email}) do
    user = Guard.Users.get_by_email!(email)
    process_session(conn, Authenticator.switch_user(conn, user))
  end

  def reset_user(conn, _params) do
    process_session(conn, Authenticator.reset_user(conn))
  end
end
