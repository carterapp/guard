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

  def create(conn, %{"user" => user}) do
    case Authenticator.create_user(user) do
      {:ok, user, jwt} -> 
      conn 
      |> put_status(:created)
      |> json(%{user: user, jwt: jwt})
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

  def send_password_reset(conn, %{"username" => username, "email" => email}) do
    user = if username == nil do
      Authenticator.get_by_username(username)
    else
      Authenticator.get_by_email(email)
    end

    case user do
      nil -> 
        Logger.debug "Failed to send link to unknown user #{username}"
        json conn, %{ok: true} #Do not allow people to probe which users are on the system 
      user ->  
        Mailer.send_reset_password_link(user, Authenticator.generate_password_reset_claim(user))
        json conn, %{ok: true}
    end
  end

  def send_login_link(conn, %{"username" => username, "email" => email}) do
    user = if username == nil do
      Authenticator.get_by_username(username)
    else
      Authenticator.get_by_email(email)
    end

    case user do
      nil ->
        Logger.debug "Failed to send link to unknown user #{username}"
        json conn, %{ok: true} #Do not allow people to probe which users are on the system 
      user -> 
        Mailer.send_login_link(user, Authenticator.generate_login_claim(user))
        json conn, %{ok: true, user: user}
    end
  end

  defp find_device(token, platform) do
    Repo.get_by(Device, token: token, platform: platform)
  end

  def register_device(conn, %{"device" => %{"platform" => platform, "token" => token} = device}) do
    user = Authenticator.current_user conn
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
