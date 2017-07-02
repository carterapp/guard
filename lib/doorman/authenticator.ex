defmodule Doorman.Authenticator do
  alias Doorman.{Repo, User, Mailer}

  defp random_bytes() do
    (:crypto.hash :sha512, (:crypto.strong_rand_bytes 512)) |> Base.encode64
  end

  def create_user(user_map) do
    email = Map.get(user_map, "email")
    username = Map.get(user_map, "username")
    
    user_map = if username == nil do
       Map.put(user_map, "username", email)
    else
      user_map
    end
    if email != nil do
      case Repo.get_by(User, email: String.downcase(email)) do
        nil -> do_create_user(user_map, email)
        _user -> {:error, %{email: "taken"}, nil}
      end
    else
      do_create_user(user_map, email)
    end
  end

  defp send_welcome_email(email, user) do
    if email != nil do
      token = generate_login_claim(user)
      Mailer.send_welcome_email(user, token)
    end

  end

  defp do_create_user(user_map, email) do
    #Only accept very few keys when creating user
    user = Map.take(user_map, ["username", "password", "password_confirmation", "fullname", "locale"])
    user = Map.put(user, "requested_email", email)
    user = Map.put(user, "confirmation_token", random_bytes())
    #Make sure user does not try to set permissions
    user = Map.delete(user, "perms")
    #Generate password if user has not provided one
    user = unless (Map.get user, "password") do
      password = random_bytes()
      Map.put(user, "password", password)
    else 
      user
    end

    changeset = User.changeset(%User{}, user)

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user, :access)
        send_welcome_email(email, user)
        {:ok, user, jwt}

      {:error, changeset} ->
        {:error, Repo.changeset_errors(changeset), changeset}
    end
  end

  def delete_user(user) do
    Repo.delete(user)
  end

  def update_user(user, changes) do
    changeset = User.changeset(user, changes)
    case Repo.update(changeset) do
      {:ok, user} -> 
        {:ok, user}
      {:error, changeset} -> 
        {:error, Repo.changeset_errors(changeset), changeset}
    end
  end

  def current_user(conn) do 
    Guardian.Plug.current_resource(conn)
  end

  def confirm_email(user, confirmation_token) do 
    if confirmation_token == user.confirmation_token do
      update_user(user, %{"email" => user.requested_email})
    else 
      {:error, "Wrong confirmation token"}
    end
  end

  def change_email(user, email) do
    update_user(user, %{"confirmation_token" => random_bytes(), "requested_email" => email})
  end

  def change_password(user, new_password) do
    update_user(user, %{"password" => new_password})
  end

  def bump_to_admin(email) do
    case get_by_email(email) do
      nil -> {:error}
      user -> Repo.update(User.changeset(user, %{"perms" => %{"admin" => ["read", "write"]}}))
    end
  end

  def drop_admin(email) do
    case get_by_email(email) do
      nil -> {:error}
      user -> Repo.update(User.changeset(user, %{"perms" => %{}}))
    end
  end


  def get_by_email(email) do
    case Repo.get_by(User, email: String.downcase(email)) do
      nil -> Repo.get_by(User, requested_email: String.downcase(email))
      confirmed -> confirmed
    end
  end

  def get_by_username(username) do
    Repo.get_by(User, username: username)
  end

  def get_by_id(id) do
    Repo.get(User, id)

  end

  def generate_login_claim(user = %User{}) do
    Guardian.encode_and_sign(user, :login, ttl: Application.get_env(:doorman, :login_ttl, {12, :hours}))
  end

  def generate_password_reset_claim(user = %User{}) do
    Guardian.encode_and_sign(user, :password_reset, ttl: Application.get_env(:doorman, :login_ttl, {12, :hours}))
  end

  def current_claims(conn)  do
    conn
    |> Guardian.Plug.current_token
    |> Guardian.decode_and_verify
  end

  def current_claim_type(conn) do
    case conn |> Guardian.Plug.current_token |> Guardian.decode_and_verify do
      {:ok, claims} ->
        Map.get(claims, "typ")
      {:error, _} -> 
        nil
    end

  end

end

