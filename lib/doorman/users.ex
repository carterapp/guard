defmodule Doorman.Users do
  alias Doorman.{Repo, User, Device}
  import Ecto.Query

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

  def create_user(changes \\ %{}) do
    case %User{}
         |> User.changeset(changes)
         |> Repo.insert() do
      {:ok, user} ->
        {:ok, user}

      {:error, changeset} ->
        {:error, Repo.changeset_errors(changeset), changeset}
    end
  end

  def get_by_email(email) do
    trimmed = trimmer(email)
    case get_by(email: trimmed) do
      nil -> get_by(requested_email: trimmed)
      confirmed -> confirmed
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
    case get_by(mobile: mobile) do
      nil -> get_by(requested_mobile: mobile)
      confirmed -> confirmed
    end
  end

  def get_by_mobile!(mobile) do
    case get_by(mobile: mobile) do
      nil -> get_by!(requested_mobile: mobile)
      confirmed -> confirmed
    end
  end

  def get_by_username(username) do
    get_by(username: trimmer(username))
  end

  def get_by_username!(username) do
    get_by!(username: trimmer(username))
  end

  defp trimmer(str) do
    str |> String.trim() |> String.downcase()
  end

  def get(id) do
    Repo.get(User, id)
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
end
