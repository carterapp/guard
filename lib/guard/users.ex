defmodule Guard.Users do
  @moduledoc false
  alias Guard.{Repo, User, Device, UserApiKey}
  import Ecto.Query

  def delete_user(user) do
    user |> Repo.delete() |> broadcast_delete()
  end

  def update_user(user, changes) do
    user
    |> User.changeset(changes)
    |> Repo.update()
    |> broadcast_update()
  end

  def update_attributes(user, attributes) do
    existing = user.attrs || %{}
    update_user(user, %{attrs: Map.merge(existing, attributes)})
  end

  def create_user(changes \\ %{}) do
    %User{}
    |> User.changeset(changes)
    |> Repo.insert()
    |> broadcast_insert()
  end

  def confirm_user_mobile(%User{} = user, mobile) do
    mobile = User.clean_mobile_number(mobile)

    if mobile && user.requested_mobile == mobile do
      update_user(user, %{mobile: mobile, requested_mobile: nil})
    else
      {:ok, user}
    end
  end

  def confirm_user_email(%User{} = user, email) do
    email = trimmer(email)

    if email && user.requested_email == email do
      update_user(user, %{email: email, requested_email: nil})
    else
      {:ok, user}
    end
  end

  def get_by_confirmed_email(email) do
    if email do
      get_by(email: trimmer(email))
    end
  end

  def get_by_confirmed_email!(email) do
    if email do
      get_by!(email: trimmer(email))
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

  def get_by_confirmed_mobile(mobile) do
    if mobile do
      get_by(mobile: User.clean_mobile_number(mobile))
    end
  end

  def get_by_confirmed_mobile!(mobile) do
    get_by!(mobile: User.clean_mobile_number(mobile))
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
    mobile = User.clean_mobile_number(mobile)

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

  defmacrop build_user_query(query, key, direction, start_key, start_id) do
    quote do
      d = unquote(direction)

      direction_symbol =
        if d == :desc || d == :desc_nulls_last || d == :desc_nulls_first do
          :<
        else
          :>
        end

      s_id = unquote(start_id)
      s_key = unquote(start_key)

      if direction_symbol == :> do
        unquote(query)
        |> where(
          [u],
          field(u, ^unquote(key)) > ^s_key or (field(u, ^unquote(key)) == ^s_key and u.id > ^s_id)
        )
      else
        unquote(query)
        |> where(
          [u],
          field(u, ^unquote(key)) < ^s_key or (field(u, ^unquote(key)) == ^s_key and u.id < ^s_id)
        )
      end
    end
  end

  def list_users(opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    direction = Keyword.get(opts, :direction, :asc)
    key = Keyword.get(opts, :key, :username)
    start_key = Keyword.get(opts, :start_key, nil)
    start_id = Keyword.get(opts, :start_id, nil)

    query =
      from(u in User,
        order_by: [{^direction, ^key}, {^direction, :id}],
        limit: ^limit
      )

    query =
      if start_key do
        query |> build_user_query(key, direction, start_key, start_id)
      else
        query
      end

    Repo.all(query)
  end

  def list_devices(%User{} = user) do
    Repo.all(from(d in Device, where: d.user_id == ^user.id))
  end

  def create_api_key(%User{} = user, permissions \\ %{}) do
    key = 64 |> :crypto.strong_rand_bytes() |> Base.encode64()

    %UserApiKey{}
    |> UserApiKey.changeset(%{key: key, permissions: permissions, user_id: user.id})
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
    Repo.all(from(k in UserApiKey, where: k.user_id == ^user.id))
  end

  def broadcast_insert({:ok, %User{} = user}) do
    broadcast_message(:on_insert, user)
  end

  def broadcast_insert(any) do
    any
  end

  def broadcast_update({:ok, %User{} = user}) do
    broadcast_message(:on_update, user)
  end

  def broadcast_update(any) do
    any
  end

  def broadcast_delete({:ok, %User{} = user}) do
    broadcast_message(:on_delete, user)
  end

  def broadcast_delete(any) do
    any
  end

  defp broadcast_message(topic, payload) do
    case Application.get_env(:guard, Guard.Users)[topic] do
      nil ->
        nil

      h ->
        h.(payload)
    end

    {:ok, payload}
  end
end
