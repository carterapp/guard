defmodule Guard.Controller.Session do
  use Phoenix.Controller
  import Guard.Controller, only: [send_error: 2, send_error: 3]
  alias Guard.{Session, Authenticator}

  def call(conn, opts) do
    try do
      super(conn, opts)
    rescue
      error -> send_error(conn, error, :internal_server_error)
    end
  end

  defp process_session(conn, {:ok, user}) do
    case Guard.Authenticator.generate_access_claim(user) do
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
    case Authenticator.current_claims(conn) do
      {:ok, claims} ->
        conn
        |> Guardian.Plug.current_token()
        |> Guard.Jwt.revoke(claims)

      _ ->
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
