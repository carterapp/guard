defmodule Doorman.Authenticator do
  alias Doorman.{Repo, User, Mailer, Device}
  import Ecto.Query

  defp pin_range() do
    Application.get_env(:doorman, :pin_range, 100000..999999)
  end

  defp pin_lifespan_mins() do
    Application.get_env(:doorman, :pin_lifespan_mins, 60)
  end


  defp random_bytes() do
    (:crypto.hash :sha512, (:crypto.strong_rand_bytes 512)) |> Base.encode64
  end

  def create_user_by_email(email, extra \\ nil) do
    create_user%{"email" => email, "username" => email}, extra
  end

  def create_user_by_mobile(mobile, extra \\ nil) do
    create_user%{"mobile" => mobile, "username" => mobile}, extra
  end

  def send_welcome_email(user) do
    {:ok, token, _} = generate_login_claim(user)
    {:ok, pin, user} = generate_pin(user)
    Mailer.send_welcome_email(user, token, pin)
  end

  def send_confirm_email(user) do
    {:ok, token, _} = generate_login_claim(user)
    Mailer.send_confirm_email(user, token)
  end

  def send_login_email(user) do
    {:ok, token, _} = generate_login_claim(user)
    {:ok, pin, user} = generate_pin(user)
    Mailer.send_login_link(user, token, pin)
  end


  def create_user_by_username(username, password, extra \\ nil) do
    map = %{"username" => username, "password" => password}
    create_user(map, extra)
  end


  defp insert_user(changeset) do
    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, jwt, _full_claims} = generate_access_claim(user)
        {:ok, user, jwt}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def create_and_confirm_user(user_map) do
    case create_user(user_map) do
      {:ok, user, jwt, extra} -> 
        send_welcome_email(user)
        {:ok, user, jwt, extra}
      other ->
        other
    end
  end

  def create_user(user_map, extra \\ nil) when is_map(user_map) do
    #Only accept very few keys when creating user
    user = Map.take(user_map, ["username", "password", "password_confirmation", "fullname", "locale"])
    email = Map.get(user_map, "email")
    user = Map.put(user, "requested_email", email)
    mobile = Map.get(user_map, "mobile")
    user = Map.put(user, "requested_mobile", mobile)
    username = Map.get(user, "username")
    username = if is_nil(username) do
      email || mobile
    else 
      username
    end
    user = Map.put(user, "username", username)

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

    if is_nil(extra) do
      with {:ok, user, jwt} <- insert_user(changeset) do
        {:ok, user, jwt, nil}
      else
        {:error, changeset} -> {:error, Repo.changeset_errors(changeset), changeset}
      end
    else
      Repo.transaction(fn ->
        with {:ok, user, jwt} <- insert_user(changeset),
             {:ok, response} <- (try do 
               extra.(user) 
             rescue 
               error -> {:error, error}
             end) do
               {:ok, user, jwt, response}
        else
          error ->
            Repo.rollback(error) 
        end
      end)
      |> case do
        {:ok, response} -> response
        {:error, {:error, %Ecto.Changeset{} = changeset}} -> {:error, Repo.changeset_errors(changeset), changeset}
        {:error, {:error, error}} -> {:error, Doorman.Controller.translate_error(error), error}
        {:error, error} -> {:error, Doorman.Controller.translate_error(error), error}
      end
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
      update_user(user, %{"email" => user.requested_email, "confirmation_token": nil})
    else 
      {:error, "wrong_confirmation_token"}
    end
  end

  def change_email(user, email) do
    update_user(user, %{"confirmation_token" => random_bytes(), 
    "requested_email" => email})
  end

  def change_password(user, new_password) do
    update_user(user, %{password: new_password})
  end

  @doc """
    Check that the given user has all the provider permissions


  ## Examples
  
  iex> Doorman.Authenticator.has_perms?(user, %{"admin" => ["read", "write"]})
  false
  """
  def has_perms?(user, %{}=required_perms) do
    !is_nil(user.perms) && Enum.reduce_while(required_perms, true, fn {key, ps}, _acc -> 
      case Map.get(user.perms, key) do
        nil -> {:halt, false}
        users_perms -> user_has_perm = Enum.reduce_while(ps, true, fn p, _acc ->
          if Enum.any?(users_perms, fn up -> p == up end) do
            {:cont, true}
          else
            {:halt, false}
          end
        end)
        if user_has_perm do
          {:cont, true}
        else 
          {:halt, false}
        end
      end
    end)
  end

  def has_perms?(user, [_|_] = perm_names) do
    Enum.reduce_while(perm_names, true, fn v, _acc -> 
      if has_perms?(user, v) do
        {:cont, true}
      else
        {:cont, false}
      end
    end) 
  end

  def has_perms?(user, perm_name) do
    !is_nil(user.perms) && Map.has_key?(user.perms, perm_name)
  end


  def add_perms(user, perms) do
    case user do
      nil -> {:error}
      user -> 
        old_perms = user.perms || %{}
        Repo.update(User.changeset(user, %{"perms" => Map.merge(old_perms, perms)})) 
    end
  end

  def drop_perm(user, name) do
    case user do
      nil -> {:error}
      user -> 
        perms = user.perms || %{}
        Repo.update(User.changeset(user, %{"perms" => Map.delete(perms, name)}))
    end
  end

  def bump_to_admin(username) do
    case get_by_username(username) do
      nil -> {:error}
      user -> Repo.update(User.changeset(user, %{"perms" => %{"admin" => ["read", "write"]}}))
    end
  end

  def drop_admin(username) do
    case get_by_username(username) do
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
    Repo.get_by(User, username: String.downcase(username))
  end

  def get_by_id(id) do
    Repo.get(User, id)

  end
  def get_by_email!(email) do
    case Repo.get_by(User, email: String.downcase(email)) do
      nil -> Repo.get_by!(User, requested_email: String.downcase(email))
      confirmed -> confirmed
    end
  end

  def get_by_username!(username) do
    Repo.get_by!(User, username: String.downcase(username))
  end

  def get_by_id!(id) do
    Repo.get!(User, id)

  end

  defp process_perms(perms) do
    if perms do
      Enum.to_list(perms)
      |> Enum.map(fn({k,v}) -> {k, Enum.map(v, fn(v) -> String.to_atom(v) end)} end)
      |> Enum.into(%{})
    else
      nil
    end
  end

  def generate_access_claim(%User{} = user) do
    perms = process_perms(user.perms)
    Doorman.Guardian.encode_and_sign(user, %{}, token_type: "access", perms: perms || %{})
  end

  def generate_login_claim(%User{} = user) do
    Doorman.Guardian.encode_and_sign(user, %{}, token_type: "login", token_ttl: Application.get_env(:doorman, :login_ttl, {12, :hours}))
  end

  def generate_password_reset_claim(%User{} = user) do
    Doorman.Guardian.encode_and_sign(user, %{}, token_type: "password_reset", token_ttl: Application.get_env(:doorman, :login_ttl, {12, :hours}))
  end

  def get_user_devices(user) do
    Repo.all(from d in Device, where: d.user_id == ^user.id)
  end

  def current_claims(conn)  do
    conn
    |> Guardian.Plug.current_token
    |> Doorman.Guardian.decode_and_verify
  end

  def current_claim_type(conn) do
    case conn |> current_claims do
      {:ok, claims} ->
        Map.get(claims, "typ")
      {:error, _} -> 
        nil
    end

  end

  def use_pin(user, pin) do
    if User.check_pin(user, pin) do
      clear_pin(user)
    else
      {:error, :wrong_pin}
    end
  end

  def generate_pin(user) do
    pin = to_string(Enum.random(pin_range()))
    {:ok, exp_time} = (DateTime.utc_now() |> DateTime.to_unix()) + 60*pin_lifespan_mins() |> DateTime.from_unix
    {:ok, user} = update_user(user, %{"pin" => pin, "pin_expiration" => exp_time})
    {:ok, pin, user}
  end

  def clear_pin(user) do
    update_user(user, %{"enc_pin" => nil, "pin_expiration" => nil})
  end

end

