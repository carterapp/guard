defmodule Guard.Repo.Migrations.CreateApiKey do
  @moduledoc false
  use Ecto.Migration

  defp table() do
    Application.get_env(:guard, :api_keys_table, :user_api_keys)
  end

  def change do
    create table(table(), primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:key, :string, null: false)
      add(:user_id, :uuid)
      add(:name, :text)
      add(:permissions, :map)

      timestamps()
    end

    create(unique_index(table(), [:key]))
  end
end
