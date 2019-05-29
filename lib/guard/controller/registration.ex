defmodule Guard.Controller.Registration do
  @moduledoc false
  require Logger
  use Guard.Controller
  alias Guard.{Repo, User, Authenticator, Device, Mailer, Users}

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
    check_user(conn, Users.get_by_username(username))
  end

  def check_account(conn, %{"email" => email}) do
    check_user(conn, Users.get_by_email(email))
  end

  def check_account(conn, %{"mobile" => mobile}) do
    check_user(conn, Users.get_by_mobile(mobile))
  end

  def create(conn, %{"user" => user}) do
    case Authenticator.create_and_confirm_user(user) do
      {:ok, user, jwt, extra} ->
        conn
        |> put_status(:created)
        |> json(%{user: user, jwt: jwt, extra: extra})

      {:error, _error, changeset} ->
        send_error(conn, changeset)
    end
  end

  def send_password_reset(conn, %{"username" => username}) do
    send_password_reset(conn, Users.get_by_username(username), username)
  end

  def send_password_reset(conn, %{"email" => email}) do
    send_password_reset(conn, Users.get_by_email(email), email)
  end

  def send_password_reset(conn, user, name) do
    case user do
      nil ->
        Logger.debug(fn -> "Failed to send link to unknown user #{name}" end)
        # Do not allow people to probe which users are on the system
        json(conn, %{ok: true})

      user ->
        do_send_password_reset(conn, user)
    end
  end

  defp do_send_password_reset(conn, user) do
    case Authenticator.generate_password_reset_claim(user) do
      {:ok, token, _} ->
        {:ok, pin, user} = Authenticator.generate_email_pin(user)
        Mailer.send_reset_password_link(user, token, pin)
        json(conn, %{ok: true})

      _ ->
        Logger.debug(fn -> "Failed to generate claim for #{user.username}" end)
        # Do not allow people to probe which users are on the system
        json(conn, %{ok: true})
    end
  end

  defp send_login(user, method) do
    if method == :mobile do
      send_login_sms(user)
    else
      do_send_login_link_email(user)
    end
  end

  defp send_confirm(user, method) do
    if method == :mobile do
      send_confirm_sms(user)
    else
      do_send_confirm_link_email(user)
    end
  end

  def send_login_link(conn, %{"email" => email} = params) do
    existing = Users.get_by_email(email)

    if existing do
      send_link(conn, &send_login/2, existing, email, :email)
    else
      create(conn, %{"user" => params})
    end
  end

  def send_login_link(conn, params) do
    send_link(conn, &send_login/2, params)
  end

  def send_confirmation_link(conn, params) do
    send_link(conn, &send_confirm/2, params)
  end

  defp send_link(conn, send_fn, %{"username" => username} = params) do
    method = if Map.get(params, "method") == "mobile", do: :mobile, else: :email
    send_link(conn, send_fn, Users.get_by_username(username), username, method)
  end

  defp send_link(conn, send_fn, %{"email" => email}) do
    send_link(conn, send_fn, Users.get_by_email(email), email, :email)
  end

  defp send_link(conn, send_fn, user, name, method) do
    case user do
      nil ->
        Logger.debug(fn -> "Failed to send link to unknown user #{name}" end)
        # Do not allow people to probe which users are on the system
        json(conn, %{ok: true})

      user ->
        resp =
          case send_fn.(user, method) do
            {:ok, user} -> %{ok: true, user: user}
            _ -> %{ok: true}
          end

        conn
        |> json(resp)
    end
  end

  defp send_login_sms(user) do
    with {:ok, pin, user} <- Authenticator.generate_pin(user) do
      Guard.Sms.send_login_mobile(user, pin)
      {:ok, user}
    end
  end

  defp do_send_login_link_email(user) do
    with {:ok, token, _claims} <- Authenticator.generate_login_claim(user),
         {:ok, pin, user} = Authenticator.generate_email_pin(user) do
      Mailer.send_login_link(user, token, pin)
      %{ok: true, user: user}
    end
  end

  defp send_confirm_sms(user) do
    with {:ok, pin, user} <- Authenticator.generate_pin(user) do
      Guard.Sms.send_confirm_mobile(user, pin)
      {:ok, user}
    end
  end

  defp do_send_confirm_link_email(user) do
    with {:ok, token, _claims} <- Authenticator.generate_login_claim(user),
         {:ok, pin, user} = Authenticator.generate_email_pin(user) do
      Mailer.send_confirm_email(user, token, pin)
      %{ok: true, user: user}
    end
  end

  defp validate_either_pin(user, pin) do
    case User.validate_pin(user, pin) do
      :ok ->
        {:ok, :mobile}

      other ->
        if user.enc_email_pin do
          case User.validate_email_pin(user, pin) do
            :ok -> {:ok, :email}
            other -> other
          end
        else
          other
        end
    end
  end

  defp get_user_from_param(params) do
    cond do
      username = Map.get(params, "username") -> Users.get_by_username!(username)
      email = Map.get(params, "email") -> Users.get_by_email!(email)
      mobile = Map.get(params, "mobile") -> Users.get_by_mobile!(mobile)
      true -> {:error, :not_found}
    end
  end

  def update_password(
        conn,
        %{
          "pin" => pin,
          "new_password" => new_password,
          "new_password_confirmation" => new_password_confirmation
        } = params
      ) do
    user = get_user_from_param(params)

    case validate_either_pin(user, pin) do
      {:ok, type} ->
        with {:ok, user} <-
               Users.update_user(user, %{
                 "password" => new_password,
                 "password_confirmation" => new_password_confirmation
               }) do
          if type == :mobile do
            Users.confirm_user_mobile(user, Map.get(params, "mobile"))
            Authenticator.clear_pin(user)
          else
            Users.confirm_user_email(user, Map.get(params, "email"))
            Authenticator.clear_email_pin(user)
          end

          json(conn, %{ok: true})
        else
          {:error, changeset} ->
            send_error(conn, changeset)
        end

      {:error, error} ->
        conn
        |> put_status(:unprocessable_entity)
        |> send_error(error)
    end
  end

  defp find_device(token, platform) do
    Repo.get_by(Device, token: token, platform: platform)
  end

  def register_device(conn, %{"device" => %{"platform" => platform, "token" => token} = device}) do
    user = Authenticator.current_user(conn)
    Logger.debug(fn -> "Registering '#{token}'" end)
    existing = find_device(token, platform)

    model =
      if existing == nil do
        %Device{}
      else
        existing
      end

    device =
      if user != nil do
        Map.put(device, "user_id", user.id)
      else
        device
      end

    changeset = Device.changeset(model, device)

    res =
      if existing == nil do
        Repo.insert(changeset)
      else
        Repo.update(changeset)
      end

    with {:ok, updated_device} <- res do
      conn
      |> put_status(:created)
      |> json(%{device: updated_device})
    end
  end

  def unregister_device(conn, %{"platform" => platform, "token" => token}) do
    user = Authenticator.current_user(conn)
    existing = find_device(token, platform)

    if existing == nil do
      conn
      |> put_status(:not_found)
      |> json(%{device: nil})
    else
      if existing.user_id == nil || existing.user_id == user.id do
        with {:ok, model} <- Repo.delete(existing) do
          json(conn, %{ok: true, device: model})
        end
      else
        conn
        |> put_status(:not_found)
        |> json(%{device: nil})
      end
    end
  end
end
