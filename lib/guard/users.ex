defmodule Guard.Users do
  alias Guard.{Repo, User, Device, UserApiKey}
  import Ecto.Query

  def delete_user(user) do
    Repo.delete(user)
  end

  def update_user(user, changes) do
    User.changeset(user, changes)
    |> Repo.update()
  end

  def create_user(changes \\ %{}) do
    %User{}
    |> User.changeset(changes)
    |> Repo.insert()
  end

  def confirm_user_mobile(%User{} = user, mobile) do
    if mobile && user.requested_mobile == mobile do
      update_user(user, %{mobile: mobile, requested_mobile: nil})
    else
      {:ok, user}
    end
  end

  def confirm_user_email(%User{} = user, email) do
    if email && user.requested_email == email do
      update_user(user, %{email: email, requested_email: nil})
    else
      {:ok, user}
    end
  end


  def get_by_email(email) do
    if email do
      trimmed = trimmer(email)
      case get_by(email: trimmed) do
        nil -> get_by(requested_email: trimmed)
        confirmed -> confirmed
      end
    end
  end

  def get_by_email!(email) do
    trimmed = trimmer(email)
    case get_by(email: trimmed) do
      nil -> get_by!(requested_email: trimmed)
      confirmed -> confirmed
    end
  end

  def get_by_mobile(mobile) do
    if mobile do
      mobile = User.clean_mobile_number(mobile)
      case get_by(mobile: mobile) do
        nil -> get_by(requested_mobile: mobile)
        confirmed -> confirmed
      end
    end
  end

  def get_by_mobile!(mobile) do
    case get_by(mobile: mobile) do
      nil -> get_by!(requested_mobile: mobile)
      confirmed -> confirmed
    end
  end

  def get_by_username(username) do
    username && get_by(username: trimmer(username))
  end

  def get_by_username!(username) do
    get_by!(username: trimmer(username))
  end

  defp trimmer(str) do
    str |> String.trim() |> String.downcase()
  end

  def get(id) do
    id && Repo.get(User, id)
  end

  def get!(id) do
    Repo.get!(User, id)
  end

  def get_by(opts) do
    Repo.get_by(User, opts)
  end

  def get_by!(opts) do
    Repo.get_by!(User, opts)
  end

  def list_devices(%User{} = user) do
    Repo.all(from(d in Device, where: d.user_id == ^user.id))
  end

  def create_api_key(%User{} = user, permissions \\ %{}) do
    key = :crypto.strong_rand_bytes(64) |> Base.encode64()
    UserApiKey.changeset(%UserApiKey{}, %{key: key, permissions: permissions, user_id: user.id})
    |> Repo.insert()
  end

  def get_api_by_key(key) do
    Repo.get_by(UserApiKey, key: key)
  end

  def delete_api_key(%UserApiKey{} = api_key) do
    Repo.delete(api_key)
  end

  def delete_api_key(key) do
    api_key = Repo.get_by!(UserApiKey, key: key)
    delete_api_key(api_key)
  end

  def list_api_keys(%User{} = user) do
    Repo.all(from k in UserApiKey, where: k.user_id == ^user.id)
  end
end
