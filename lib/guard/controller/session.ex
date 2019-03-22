defmodule Guard.Controller.Session do
  use Guard.Controller
  alias Guard.{Session, Authenticator, User, UserApiKey}

  @claim_whitelist ["usr", "ctx"]
  @refresh_token "refresh"

  defp remember_user?(_conn) do
    Application.get_env(:guard, Guard.Jwt)[:remember_user]
  end

  defp remember_me(conn, %User{} = user, claims, opts) do
    if remember_user?(conn) do
      conn
      |> Guard.Jwt.Plug.remember_me(user, claims, opts)
    else
      conn
    end
  end

  defp output_new_session(conn, user, claims) do
    with {:ok, session} <- Session.current_session(conn) do
      conn
      |> remember_me(user, claims, token_type: @refresh_token)
      |> put_status(:created)
      |> json(session)
    end
  end

  defp process_session(conn, {:ok, %User{} = user}) do
    process_session(conn, {:ok, user, %{}})
  end

  defp process_session(conn, {:ok, %User{} = user, claims}) do
    conn
    |> Authenticator.sign_in(user, claims |> Map.take(@claim_whitelist))
    |> output_new_session(user, claims)
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
        context = claims["ctx"]

        extra =
          %{root_user: root_user, context: context}
          |> Enum.filter(fn {_k, v} -> v end)
          |> Enum.into(%{})

        conn
        |> put_status(:created)
        |> json(
          Map.merge(%{jwt: jwt, user: user, perms: user.perms, root_user: root_user}, extra)
        )

      {:error, error} ->
        send_error(conn, error)
    end
  end

  def set_context(conn, %{"context" => context}) do
    process_session(conn, Session.set_context(conn, context))
  end

  def set_context(conn, context) do
    process_session(conn, Session.set_context(conn, context))
  end

  def clear_context(conn, _) do
    process_session(conn, Session.clear_context(conn))
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
    conn
    |> Guardian.Plug.current_resource()
    |> case do
      %User{} ->
        conn
        |> Guard.Jwt.Plug.sign_out(clear_remember_me: remember_user?(conn))

      %UserApiKey{} ->
        conn
        |> Guardian.Plug.current_token()
        |> Guard.ApiKey.revoke()

        conn

      _any ->
        conn
    end
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
