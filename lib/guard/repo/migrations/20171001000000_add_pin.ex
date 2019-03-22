defmodule Guard.Repo.Migrations.AddPin do
  @moduledoc false
  use Ecto.Migration

  def users_table() do
    Application.get_env(:guard, :users_table, :users)
  end

  def change do
    alter table(users_table()) do
      add(:pin, :string)
      add(:pin_timestamp, :utc_datetime)
    end
  end
end
