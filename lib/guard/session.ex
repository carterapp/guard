defmodule Guard.Session do
  alias Guard.{User, Authenticator, Users, UserApiKey}
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
        if Enum.reduce_while(all_perms, true, fn perm, _acc ->
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
        if Enum.reduce_while(any_perms, true, fn perm, _acc ->
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

      _ ->
        {:ok, user}
    end
  end

  defp check_password_with_message(user, password, params) do
    case check_password(user, password) do
      true ->
        verify_params(user, params)

      _ ->
        {:error, :wrong_password}
    end
  end

  defp check_pin_with_message(pin_fn, user, pin, params) do
    case pin_fn.(user, pin) do
      {:ok, user} ->
        verify_params(user, params)

      error ->
        error
    end
  end

  def authenticate(%{"email" => email, "password" => password} = params) do
    user = Users.get_by_email(email)
    check_password_with_message(user, password, params)
  end

  def authenticate(%{"username" => username, "password" => password} = params) do
    user = Users.get_by_username(username)

    check_password_with_message(user, password, params)
  end

  def authenticate(%{"username" => username, "pin" => pin} = params) do
    user = Users.get_by_username(username)

    check_pin_with_message(&Authenticator.use_either_pin/2, user, pin, params)
  end

  def authenticate(%{"mobile" => mobile, "pin" => pin} = params) do
    user = Users.get_by_mobile(mobile)

    case check_pin_with_message(&Authenticator.use_pin/2, user, pin, params) do
      {:ok, user} ->
        Users.confirm_user_mobile(user, mobile)

      error ->
        error
    end
  end

  def authenticate(%{"email" => email, "pin" => pin} = params) do
    user = Users.get_by_email(email)

    case check_pin_with_message(&Authenticator.use_email_pin/2, user, pin, params) do
      {:ok, user} ->
        Users.confirm_user_email(user, email)

      error ->
        error
    end
  end

  def authenticate(%{"token" => token}) do
    authenticate_token(token)
  end

  def authenticate({:jwt, jwt}) do
    authenticate_token(jwt)
  end

  def authenticate(_) do
    {:error, :missing_credentials}
  end

  def authenticate(conn, params) do
    case authenticate(params) do
      {:ok, user} ->
        {:ok, user}

      {:error, :missing_credentials} ->
        case Guardian.Plug.current_token(conn) do
          nil ->
            {:error, :missing_token}

          token ->
            case Guard.Jwt.refresh(token) do
              {:ok, _old, {new_token, new_claims}} -> {:ok, new_token, new_claims}
              other -> other
            end
        end

      other ->
        other
    end
  end

  defp authenticate_token(token) do
    case Guard.Jwt.decode_and_verify(token) do
      {:ok, claims} ->
        with {:ok, user} <- user_from_claim(claims) do
          {:ok, user, claims}
        end

      _ ->
        {:error, :bad_token}
    end
  end

  defp user_from_claim(claims) do
    case claims do
      %{"sub" => "User:" <> user_id} ->
        case Users.get(user_id) do
          nil -> {:error, :bad_claims}
          user -> confirm_user_email_from_claims(claims, user)
        end

      _ ->
        {:error, :bad_claims}
    end
  end

  defp confirm_user_email_from_claims(claims, user) do
    case Map.get(claims, "typ") do
      "login" ->
        if user.requested_email != nil &&
             user.requested_email == Map.get(claims, "requested_email") do
          Users.update_user(user, %{email: user.requested_email, requested_email: nil})
        else
          {:ok, user}
        end

      _ ->
        {:ok, user}
    end
  end

  defp check_password(user, password) do
    case user do
      nil -> false
      _ -> User.check_password(user, password)
    end
  end

  defp decode_permissions(%User{}, claims) do
    Guard.Jwt.decode_permissions_from_claims(claims)
  end

  defp decode_permissions(%UserApiKey{}, claims) do
    Guard.Jwt.decode_permissions_from_claims(claims)
  end

  defp decode_permissions(_resource, _claims) do
    %{}
  end

  defp add_token(map, conn, %User{}) do
    map |> Map.put(:jwt, Guardian.Plug.current_token(conn))
  end

  defp add_token(map, conn, %UserApiKey{}) do
    map |> Map.put(:key, Guardian.Plug.current_token(conn))
  end

  defp add_token(map, _conn, _resource) do
    map
  end

  def current_session(conn) do
    case Authenticator.current_claims(conn) do
      {:ok, claims} ->
        resource = Guardian.Plug.current_resource(conn)
        perms = decode_permissions(resource, claims)
        user = Guard.Authenticator.current_user(conn)
        root_user = claims["usr"]

        extra =
          if root_user do
            %{root_user: root_user}
          else
            %{}
          end

        {:ok, %{perms: perms, user: user} |> Map.merge(extra) |> add_token(conn, resource)}

      any ->
        any
    end
  end
end
