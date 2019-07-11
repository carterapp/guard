defmodule Guard.Repo.Migrations.AddRegisteredAt do
  @moduledoc false
  use Ecto.Migration

  def devices_table() do
    Application.get_env(:guard, :devices_table, :devices)
  end

  def change do
    alter table(devices_table()) do
      add(:registered_at, :utc_datetime)
    end
  end
end
