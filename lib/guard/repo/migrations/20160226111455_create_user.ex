defmodule Guard.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def users_table() do
    Application.get_env(:guard, :users_table, :users)
  end

  def change do
    create table(users_table(), primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:username, :string, null: false)
      add(:fullname, :string)
      add(:locale, :string)
      add(:email, :string, null: true)
      add(:requested_email, :string)
      add(:enc_password, :string, null: false)
      add(:perms, :map)
      add(:provider, :map)
      add(:confirmation_token, :string)
      add(:attrs, :map)

      timestamps()
    end

    create(unique_index(users_table(), [:username]))
    create(unique_index(users_table(), [:email]))
  end
end
