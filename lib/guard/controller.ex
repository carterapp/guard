defmodule Guard.Controller do
  require Logger

  import Plug.Conn, only: [put_status: 2, put_resp_content_type: 2, send_resp: 3]

  defmacro __using__(_opts) do
    quote do
      use Plug.Builder
      import Plug.Conn
      import Guard.Controller

      plug(Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        json_decoder: Jason
      )
    end
  end

  defmacro resources do
    quote do
      # Create new account
      post("/registration", Guard.Controller.Registration, :create)

      # Request a password reset
      post("/registration/reset", Guard.Controller.Registration, :send_password_reset)
      # Send magic link
      post("/registration/link", Guard.Controller.Registration, :send_login_link)
      # Check availability
      post("/registration/check", Guard.Controller.Registration, :check_account)

      # Register for push
      post("/registration/device", Guard.Controller.Registration, :register_device)
      # Unregister for push
      delete(
        "/registration/device/:platform/:token",
        Guard.Controller.Registration,
        :unregister_device
      )

      # Login
      post("/session", Guard.Controller.Session, :create)
      # Show current session
      get("/session", Guard.Controller.ActiveSession, :show)
      # Restore session with given JWT
      get("/session/:token", Guard.Controller.Session, :restore)
      # Logout
      delete("/session", Guard.Controller.Session, :delete)
      put("/session/switch/:id", Guard.Controller.Session, :switch_user)
      put("/session/switch/username/:username", Guard.Controller.Session, :switch_user)
      put("/session/switch/email/:email", Guard.Controller.Session, :switch_user)
      put("/session/switch/mobile/:mobile", Guard.Controller.Session, :switch_user)

      delete("/session/switch", Guard.Controller.Session, :reset_user)

      # Update current account
      put("/account", Guard.Controller.Account, :update)
      # Update attributes for current account
      post("/account/attributes", Guard.Controller.Account, :update_attributes)
      # Delete account
      delete("/account", Guard.Controller.Account, :delete)
      # Update password for current account
      put("/account/password", Guard.Controller.PasswordReset, :update_password)
      # Update password for account by one-time-pin
      put("/account/setpassword", Guard.Controller.Registration, :update_password)
    end
  end

  defmacro key_resources do
    quote do
      get("/keys", Guard.Controller.KeyController, :list_keys)
      post("/keys", Guard.Controller.KeyController, :create_key)
      delete("/keys/:key", Guard.Controller.KeyController, :revoke_key)
    end
  end

  defmacro admin_resources do
    quote do
      get("/users/:id", Guard.Controller.UserController, :get_user)
      get("/users/username/:username", Guard.Controller.UserController, :get_user)
      get("/users/email/:email", Guard.Controller.UserController, :get_user)
      get("/users/mobile/:mobile", Guard.Controller.UserController, :get_user)
      # Create user
      post("/users", Guard.Controller.UserController, :create_user)
      # Update given user
      put("/users/:id", Guard.Controller.UserController, :update_user)
      # Delete given user
      delete("/users/:id", Guard.Controller.UserController, :delete_user)
      # Show all registered uses
      get("/users", Guard.Controller.UserController, :list_all_users)
    end
  end

  def send_error(conn, %{message: message, plug_status: status_code} = _error) do
    send_error(conn, message, status_code)
  end

  def send_error(conn, %Ecto.Changeset{} = cs) do
    send_error(conn, Guard.Repo.changeset_errors(cs), :unprocessable_entity)
  end

  def send_error(conn, %Ecto.Query.CastError{}) do
    send_error(conn, :not_found, :not_found)
  end

  def send_error(conn, %Ecto.NoResultsError{}) do
    send_error(conn, :not_found, :not_found)
  end

  def send_error(conn, %Plug.Conn.WrapperError{reason: reason}) do
    send_error(conn, reason)
  end

  def send_error(conn, error, status_code \\ :unprocessable_entity) do
    Logger.debug("ERROR: #{conn.request_path}\n#{inspect(error)}")

    conn
    |> put_status(status_code)
    |> json(%{error: translate_error(error)})
  end

  def json(conn, value) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(conn.status || :ok, Jason.encode_to_iodata!(value))
  end

  def translate_error(reason) do
    cond do
      is_tuple(reason) -> tuple_to_map(%{}, Tuple.to_list(reason))
      Exception.exception?(reason) -> translate_error(Exception.message(reason))
      true -> reason
    end
  end

  defp tuple_to_map(acc, list) do
    if length(list) > 2 do
      [k, v | tail] = list
      tuple_to_map(Map.put(acc, k, v), tail)
    else
      acc
    end
  end
end
