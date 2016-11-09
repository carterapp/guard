defmodule Doorman.Session do
  alias Doorman.{Repo, User}


  def authenticate(%{"email" => email, "password" => password}) do
    user = Repo.get_by(User, email: String.downcase(email))

    case check_password(user, password) do
      true -> {:ok, user}
      _ -> {:error, "wrong password"}
    end
  end

  def authenticate(%{"username" => username, "password" => password}) do
    user = Repo.get_by(User, username: username)

    case check_password(user, password) do
      true -> {:ok, user}
      _ -> {:error, "wrong password"}
    end
  end

  def authenticate({:jwt, jwt}) do
    case Guardian.decode_and_verify(jwt) do
      {:ok, claims} -> user_from_claim(claims)
      _ -> {:error, "bad token"}
    end
  end
  
  def authenticate(_) do
    {:error, "missing credentials"}
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
