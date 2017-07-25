defmodule Doorman.Controller do
  require Logger
  use Phoenix.Controller

  defmacro resources do
    quote do
      post "/registration", Doorman.Controller.Registration, :create #Create new account
      post "/registration/confirm/:user_id/:confirmation_token", Doorman.Controller.Registration, :confirm #Confirm email

      post "/registration/reset", Doorman.Controller.Registration, :send_password_reset #Request a password reset
      post "/registration/link", Doorman.Controller.Registration, :send_login_link #Send magic link
      post "/registration/check", Doorman.Controller.Registration, :check_account #Send magic link
      
      post "/registration/device", Doorman.Controller.Registration, :register_device #Register for push
      delete "/registration/device/:platform/:token", Doorman.Controller.Registration, :unregister_device #Unregister for push

      post "/session", Doorman.Controller.Session, :create #Login
      get "/session", Doorman.Controller.ActiveSession, :show #Show current session
      get "/session/:token", Doorman.Controller.Session, :restore #Restore session with given JWT
      delete "/session", Doorman.Controller.Session, :delete #Logout

      put "/account", Doorman.Controller.Account, :update #Update current account
      delete "/account", Doorman.Controller.Account, :delete #Delete account
      put "/account/password", Doorman.Controller.PasswordReset, :update_password #Update password for current account

    end
  end

  defmacro admin_resources do
    quote do
      put "/users/:userid", Doorman.Controller.Registration, :update #Update given user
      delete "/users/:userid", Doorman.Controller.Registration, :delete #Delete given user
      get "/users", Doorman.Controller.Registration, :index #Show all registered uses
      get "/audit/:user_id", Doorman.Controller.Audit, :audit_trail #Show audit trail for user
    end
  end

  def send_error(conn, %{message: message, plug_status: status_code}=error) do
    Logger.error("#{inspect error}")
    conn 
    |> put_status(status_code)
    |> json(%{error: translate_error(message)})
  end

    def send_error(conn, error, status_code \\ :unprocessable_entity) do
    Logger.error("#{inspect error}")
    conn 
    |> put_status(status_code)
    |> json(%{error: translate_error(error)})
  end

  def unauthenticated(conn, %{reason: {:error, reason}}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: translate_error(reason)})
  end


  def unauthenticated(conn, _params) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "unauthenticated"})
  end

  def unauthorized(conn, %{reason: {:error, reason}}) do
    conn
    |> put_status(:forbidden)
    |> json(%{error: translate_error(reason)})
  end


  def unauthorized(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> json(%{error: "forbidden"})
  end

  defp translate_error(reason) do 
    cond do
      is_tuple(reason) -> tuple_to_map(%{}, Tuple.to_list(reason))
      Exception.exception?(reason) -> translate_error(Exception.message(reason))
      true -> reason
    end
  end

  defp tuple_to_map(acc, list) do
    if length list > 2 do
      [k, v | tail] = list
      tuple_to_map(Map.put(acc, k, v), tail)
    else 
      acc
    end

  end

end
