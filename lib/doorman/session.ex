defmodule Doorman.Session do
  alias Doorman.{Repo, User}

  defp check_password_with_message(user, password) do
    case check_password(user, password) do
      true -> {:ok, user}
      _ -> {:error, "wrong_password"}
    end

  end

  def authenticate(%{"email" => email, "password" => password}) do
    user = Repo.get_by(User, email: String.downcase(email))

    if user == nil do
      check_password_with_message(Repo.get_by(User, requested_email: String.downcase(email)), password)
    else
      check_password_with_message(user, password)
    end

  end

  def authenticate(%{"username" => username, "password" => password}) do
    user = Repo.get_by(User, username: username)

    check_password_with_message(user, password)
  end

  def authenticate(%{"token" => token}) do
    case Guardian.decode_and_verify(token) do
      {:ok, claims} -> user_from_claim(claims)
      _ -> {:error, "bad token"}
    end
  end

  def authenticate({:jwt, jwt}) do
    case Guardian.decode_and_verify(jwt) do
      {:ok, claims} -> user_from_claim(claims)
      _ -> {:error, "bad_token"}
    end
  end
  
  def authenticate(_) do
    {:error, "missing_credentials"}
  end


  defp user_from_claim(claims) do
    case claims do 
      %{"sub" => "User:" <> user_id} -> {:ok, Repo.get(User, user_id)}
      _ -> {:error, "bad claims"}
    end

  end

  defp check_password(user, password) do
    case user do
      nil -> false
      _ -> User.check_password(user, password)
    end
  end


end
