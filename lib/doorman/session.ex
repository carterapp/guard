defmodule Doorman.Session do
  alias Doorman.{Repo, User, Authenticator, Users}

  defp check_password_with_message(user, password, params) do
    case check_password(user, password) do
      true -> 
        case params do
        %{"perm" => perm} ->
          if Map.has_key?(user.perms || %{}, perm) do
            {:ok, user}
          else 
            {:error, :forbidden}
          end
         _ -> {:ok, user}
        end
      _ -> {:error, "wrong_password"}
    end
  end

  defp check_pin_with_message(user, pin, params) do
    case Authenticator.use_pin(user, pin) do
      {:ok, user} -> 
        case params do
        %{"perm" => perm} ->
          if Map.has_key?(user.perms || %{}, perm) do
            {:ok, user}
          else 
            {:error, :forbidden}
          end
         _ -> {:ok, user}
        end
      error -> error
    end
  end

  def authenticate(params = %{"email" => email, "password" => password}) do
    user = Users.get_by(email: String.downcase(email))
    if user == nil do
      check_password_with_message(Users.get_by!(requested_email: String.downcase(email)), password, params)
    else
      check_password_with_message(user, password, params)
    end
  end

  def authenticate(params = %{"username" => username, "password" => password}) do
    user = Users.get_by!(username: username)

    check_password_with_message(user, password, params)
  end

  def authenticate(params = %{"username" => username, "pin" => pin}) do
    user = Users.get_by!(username: username)

    check_pin_with_message(user, pin, params)
  end

  def authenticate(params = %{"mobile" => mobile, "pin" => pin}) do
    user = Users.get_by(mobile: mobile) || Users.get_by!(requested_mobile: mobile)
    check_pin_with_message(user, pin, params)
  end



  def authenticate(%{"token" => token}) do
    case Doorman.Guardian.decode_and_verify(token) do
      {:ok, claims} -> user_from_claim(claims)
      _ -> {:error, "bad_token"}
    end
  end

  def authenticate({:jwt, jwt}) do
    case Doorman.Guardian.decode_and_verify(jwt) do
      {:ok, claims} -> user_from_claim(claims)
      _ -> {:error, "bad_token"}
    end
  end
  
  def authenticate(_) do
    {:error, "missing_credentials"}
  end


  defp user_from_claim(claims) do
    case claims do 
      %{"sub" => "User:" <> user_id} -> 
        case Repo.get(User, user_id) do
          nil -> {:error, "bad_claims"}
          user -> {:ok, user}
        end
      _ -> {:error, "bad_claims"}
    end
  end

  defp check_password(user, password) do
    case user do
      nil -> false
      _ -> User.check_password(user, password)
    end
  end


end
