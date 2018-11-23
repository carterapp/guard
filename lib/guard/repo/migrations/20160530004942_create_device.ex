defmodule Guard.Repo.Migrations.CreateDevice do
  use Ecto.Migration

  def device_table() do
    Application.get_env(:guard, :devices_table, :devices)
  end

  def change do
    create table(device_table(), primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string, null: false
      add :platform, :string, null: false
      add :user_id, :uuid
      add :last_sent, :utc_datetime

      timestamps()
    end

    create unique_index(device_table(), [:token, :platform])

  end
end
