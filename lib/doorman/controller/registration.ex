defmodule Doorman.Controller.Registration do
  require Logger
  use Phoenix.Controller
  alias Doorman.{Repo, User, Authenticator, Device, Mailer}
  import Doorman.Controller, only: [send_error: 2, send_error: 3]

  def call(conn, opts) do
    try do
      super(conn, opts)
    rescue
      error -> send_error(conn, error, :internal_server_error)
    end
  end

  defp check_user(conn, user) do
    case user do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{ok: false})
      _ ->
        conn
        |> put_status(:ok)
        |> json(%{ok: true})
    end
  end

  def check_account(conn, %{"username" => username}) do
    check_user(conn, Authenticator.get_by_username(username))
  end

  def check_account(conn, %{"email" => email}) do
    check_user(conn, Authenticator.get_by_email(email))
  end


  def create(conn, %{"user" => user}) do
    case Authenticator.create_user(user) do
      {:ok, user, jwt, extra} -> 
      conn 
      |> put_status(:created)
      |> json(%{user: user, jwt: jwt, extra: extra})
      {:error, error, _} -> 
        send_error(conn, error)
    end

  end

  def confirm(conn, %{"confirmation_token" => token, "user_id" => user_id}) do
    user = Repo.get(User, user_id)
    case Authenticator.confirm_email(user, token) do
      {:ok, user} -> 
        json conn, %{user: user}
      {:error, error, _} -> 
        send_error(conn, error)
    end 
  end

  def send_password_reset(conn, %{"username" => username}) do
      send_password_reset(conn, Authenticator.get_by_username(username), username)
  end
  def send_password_reset(conn, %{"email" => email}) do
    send_password_reset(conn, Authenticator.get_by_email(email), email)
  end

  def send_password_reset(conn, user, name) do
    case user do
      nil -> 
        Logger.debug "Failed to send link to unknown user #{name}"
        json conn, %{ok: true} #Do not allow people to probe which users are on the system 
      user ->  
        case Authenticator.generate_password_reset_claim(user) do
          {:ok, token, _} -> 
            {:ok, user} = Authenticator.generate_pin(user)
            Mailer.send_reset_password_link(user, token)
            json conn, %{ok: true}
          _ -> 
            Logger.debug "Failed to generate claim for #{name}"
            json conn, %{ok: true} #Do not allow people to probe which users are on the system 
        end
    end
  end

  def send_login_link(conn,  %{"username" => username}) do
    send_login_link(conn, Authenticator.get_by_username(username), username)
  end

  def send_login_link(conn, user=%{"email" => email}) do
    existing_user = Authenticator.get_by_email(email)
    if existing_user do
      send_login_link(conn, existing_user, email)
    else
      create(conn, %{"user" => user})
    end
  end


  def send_login_link(conn, user, name) do
    case user do
      nil ->
        Logger.debug "Failed to send link to unknown user #{name}"
        json conn, %{ok: true} #Do not allow people to probe which users are on the system 
      user -> 
        case Authenticator.generate_login_claim(user) do
          {:ok, token, _} -> 
            Mailer.send_login_link(user, token)
            json conn, %{ok: true, user: user}
          _ -> 
            Logger.debug "Failed to generate claim for #{name}"
            json conn, %{ok: true} #Do not allow people to probe which users are on the system 
        end
    end
  end

  def update_password(conn, %{"username" => username, "pin" => pin, "new_password" => new_password, "new_password_confirmation" => new_password_confirmation}) do
    user = Authenticator.get_by_username(username)
    case User.check_pin(user, pin) do
      true ->
        case Authenticator.update_user(user, %{"password" => new_password, "password_confirmation" => new_password_confirmation}) do
          {:ok, _user} -> 
            Authenticator.clear_pin(user)
            json(conn, %{ok: true})
          {:error, error, _changeset} ->
            send_error(conn, error)
        end
      false ->
        conn
        |> put_status(:precondition_failed)
        |> json(%{ok: false})

    end
  end


  defp find_device(token, platform) do
    Repo.get_by(Device, token: token, platform: platform)
  end

  def register_device(conn, %{"device" => %{"platform" => platform, "token" => token} = device}) do
    user = Authenticator.current_user conn
    Logger.debug "Registering '#{token}'"
    existing = find_device(token, platform)
    if (existing == nil || existing.user_id == nil) do
      model = if existing == nil do
        %Device{}
      else
        existing
      end
      device = if user != nil do
        Map.put(device, "user_id", user.id)
      else 
        device
      end
      changeset = Device.changeset(model, device)
      res = if existing == nil do
        Repo.insert(changeset)
      else 
        Repo.update(changeset)
      end

      case res do
        {:ok, updated_device} -> 
        conn 
        |> put_status(:created)
        |> json(%{device: updated_device})
        {:error, changeset} -> 
        send_error(conn, Repo.changeset_errors(changeset))
      end
    else
      if user != nil && existing.user_id != user.id do
        conn 
        |> put_status(:forbidden)
        |> json(%{device: nil})

      else
        conn 
        |> put_status(:found)
        |> json(%{device: existing})

      end
    end
  end

  def unregister_device(conn, %{"platform" => platform, "token" => token}) do
    user = Authenticator.current_user conn
    existing = find_device(token, platform)
    if (existing == nil) do
      conn
      |> put_status(:not_found)
      |> json(%{device: nil})
    else 
      if existing.user_id == nil || existing.user_id == user.id do
        case Repo.delete(existing) do
          {:ok, model} ->
            json conn, %{ok: true, device: model}
          {:error, changeset} ->
            send_error(conn, Repo.changeset_errors(changeset))
        end
      else 
        conn
        |> put_status(:not_found)
        |> json(%{device: nil})
      end
    end


  end
  
end
