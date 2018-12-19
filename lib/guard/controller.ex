defmodule Guard.Controller do
  require Logger
  use Phoenix.Controller

  defmacro resources do
    quote do
      post "/registration", Guard.Controller.Registration, :create #Create new account

      post "/registration/reset", Guard.Controller.Registration, :send_password_reset #Request a password reset
      post "/registration/link", Guard.Controller.Registration, :send_login_link #Send magic link
      post "/registration/check", Guard.Controller.Registration, :check_account #Check availability

      post "/registration/device", Guard.Controller.Registration, :register_device #Register for push
      delete "/registration/device/:platform/:token", Guard.Controller.Registration, :unregister_device #Unregister for push

      post "/session", Guard.Controller.Session, :create #Login
      get "/session", Guard.Controller.ActiveSession, :show #Show current session
      get "/session/:token", Guard.Controller.Session, :restore #Restore session with given JWT
      delete "/session", Guard.Controller.Session, :delete #Logout
      put "/session/switch/:id", Guard.Controller.Session, :switch_user
      put "/session/switch/username/:username", Guard.Controller.Session, :switch_user
      put "/session/switch/email/:email", Guard.Controller.Session, :switch_user
      put "/session/switch/mobile/:mobile", Guard.Controller.Session, :switch_user

      delete "/session/switch", Guard.Controller.Session, :reset_user

      put "/account", Guard.Controller.Account, :update #Update current account
      post "/account/attributes", Guard.Controller.Account, :update_attributes #Update attributes for current account
      delete "/account", Guard.Controller.Account, :delete #Delete account
      put "/account/password", Guard.Controller.PasswordReset, :update_password #Update password for current account
      put "/account/setpassword", Guard.Controller.Registration, :update_password #Update password for account by one-time-pin

    end
  end

  defmacro key_resources do
    quote do
      get "/keys", Guard.Controller.KeyController, :list_keys
      post "/keys", Guard.Controller.KeyController, :create_key
      delete "/keys/:key", Guard.Controller.KeyController, :revoke_key
    end
  end

  defmacro admin_resources do
    quote do
      get "/users/:id", Guard.Controller.UserController, :get_user 
      get "/users/username/:username", Guard.Controller.UserController, :get_user 
      get "/users/email/:email", Guard.Controller.UserController, :get_user 
      get "/users/mobile/:mobile", Guard.Controller.UserController, :get_user 
      put "/users/:id", Guard.Controller.UserController, :update_user #Update given user
      delete "/users/:id", Guard.Controller.UserController, :delete_user #Delete given user
      get "/users", Guard.Controller.UserController, :list_all_users #Show all registered uses
    end
  end

  def send_error(conn, %{message: message, plug_status: status_code}=_error) do
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
    Logger.debug("ERROR: #{conn.request_path}\n#{inspect error}")
    conn
    |> put_status(status_code)
    |> json(%{error: translate_error(error)})
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
