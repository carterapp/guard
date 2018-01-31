defmodule Doorman.Repo.Migrations.AddMobile do
  use Ecto.Migration

  def users_table() do
    Application.get_env(:doorman, :users_table, :users)
  end

  def change do
    alter table(users_table()) do
      add :mobile, :string
      add :requested_mobile, :string
    end

  end
end
