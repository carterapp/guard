defmodule Guard.Repo.Migrations.ConfirmationPin do
  @moduledoc false
  use Ecto.Migration

  def users_table() do
    Application.get_env(:guard, :users_table, :users)
  end

  def change do
    alter table(users_table()) do
      remove(:confirmation_token)
      add(:enc_email_pin, :string)
      add(:email_pin_expiration, :utc_datetime)
    end
  end
end
