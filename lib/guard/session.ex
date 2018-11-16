defmodule Guard.Session do
  alias Guard.{User, Authenticator, Users}
  require Logger


  defp has_perm?(user, perm) do
    Map.has_key?(user.perms || %{}, perm)
  end

  defp verify_params(user, params) do
    case params do
      %{"perm" => perm} ->
        if has_perm?(user, perm) do
          {:ok, user}
        else
          {:error, :forbidden}
        end
      %{"all_perms" => all_perms} ->
        if Enum.reduce_while(all_perms, true, fn (perm, _acc) ->
          if has_perm?(user, perm) do
            {:cont, true}
          else
            {:halt, false}
          end
        end) do
          {:ok, user}
        else
          {:error, :forbidden}
        end

      %{"any_perms" => any_perms} ->
        if Enum.reduce_while(any_perms, true, fn (perm, _acc) ->
          if has_perm?(user, perm) do
            {:halt, true}
          else
            {:cont, false}
          end
        end) do
          {:ok, user}
        else
          {:error, :forbidden}
        end
      _ -> {:ok, user}
    end
  end

  defp check_password_with_message(user, password, params) do
    case check_password(user, password) do
      true ->
        verify_params(user, params)
      _ -> {:error, :wrong_password}
    end
  end

  defp check_pin_with_message(user, pin, params) do
    case Authenticator.use_pin(user, pin) do
      {:ok, user} ->
        verify_params(user, params)
      error -> error
    end
  end

  def authenticate(params = %{"email" => email, "password" => password}) do
    user = Users.get_by_email(email)
    check_password_with_message(user, password, params)
  end

  def authenticate(params = %{"username" => username, "password" => password}) do
    user = Users.get_by_username(username)

    check_password_with_message(user, password, params)
  end

  def authenticate(params = %{"username" => username, "pin" => pin}) do
    user = Users.get_by_username(username)

    check_pin_with_message(user, pin, params)
  end

  def authenticate(params = %{"mobile" => mobile, "pin" => pin}) do
    user = Users.get_by(mobile: mobile) || Users.get_by!(requested_mobile: mobile)
    case check_pin_with_message(user, pin, params) do
      {:ok, user} ->
        confirm_user_mobile(user, mobile)
      error -> error
    end
  end


  def authenticate(%{"token" => token}) do
    case Guard.Guardian.decode_and_verify(token) do
      {:ok, claims} -> user_from_claim(claims)
      _ -> {:error, :bad_token}
    end
  end

  def authenticate({:jwt, jwt}) do
    case Guard.Guardian.decode_and_verify(jwt) do
      {:ok, claims} -> user_from_claim(claims)
      _ -> {:error, :bad_token}
    end
  end

  def authenticate(_) do
    {:error, :missing_credentials}
  end

  def authenticate(conn, params) do
    case authenticate(params) do
      {:ok, user} -> {:ok, user}
      {:error, :missing_credentials} ->
        case Guardian.Plug.current_token(conn) do
          nil -> {:error, :missing_token}
          token ->
            case Guard.Guardian.refresh(token) do
              {:ok, _old, {new_token, new_claims}} -> {:ok, new_token, new_claims}
              other -> other
            end
        end
      other -> other
    end
  end

  defp confirm_user_mobile(%User{} = user, mobile) do
    if user.requested_mobile == mobile do
      Users.update_user(user, %{mobile: mobile, requested_mobile: nil})
    else
      {:ok, user}
    end
  end

  defp user_from_claim(claims) do
    case claims do
      %{"sub" => "User:" <> user_id} ->
        case Users.get(user_id) do
          nil -> {:error, :bad_claims}
          user -> confirm_user_email(claims, user)
        end
      _ -> {:error, :bad_claims}
    end
  end

  defp confirm_user_email(claims, user) do
    case Map.get(claims, "typ") do
      "login" ->
        if user.requested_email != nil && user.requested_email == Map.get(claims, "requested_email") do
          Users.update_user(user, %{email: user.requested_email, requested_email: nil})
        else
          {:ok, user}
        end

      _ -> {:ok, user}
    end
  end

  defp check_password(user, password) do
    case user do
      nil -> false
      _ -> User.check_password(user, password)
    end
  end


end
