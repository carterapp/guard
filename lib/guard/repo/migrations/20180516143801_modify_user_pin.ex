defmodule Guard.Repo.Migrations.ModifyUserPin do
  use Ecto.Migration

  def users_table() do
    Application.get_env(:guard, :users_table, :users)
  end

  def change do
    rename table(users_table()), :pin, to: :enc_pin
    rename table(users_table()), :pin_timestamp, to: :pin_expiration

    create unique_index(users_table(), [:mobile])
  end
end
