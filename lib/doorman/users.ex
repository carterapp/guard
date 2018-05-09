defmodule Doorman.Users do
  alias Doorman.{Repo, User, Device}
  import Ecto.Query


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
    Repo.all(from d in Device, where: d.user_id == ^user.id)
  end
 
end
