defmodule Guard.Migrations do
  @moduledoc false
  def run(repo) do
    Ecto.Migrator.up(repo, 20_160_226_111_455, Guard.Repo.Migrations.CreateUser)
    Ecto.Migrator.up(repo, 20_160_530_004_942, Guard.Repo.Migrations.CreateDevice)
    Ecto.Migrator.up(repo, 20_171_010_000_000, Guard.Repo.Migrations.AddPin)
    Ecto.Migrator.up(repo, 20_180_131_210_142, Guard.Repo.Migrations.AddMobile)
    Ecto.Migrator.up(repo, 20_180_516_143_801, Guard.Repo.Migrations.ModifyUserPin)
    Ecto.Migrator.up(repo, 20_181_128_202_721, Guard.Repo.Migrations.ConfirmationPin)
    Ecto.Migrator.up(repo, 20_181_217_105_542, Guard.Repo.Migrations.CreateApiKey)
    Ecto.Migrator.up(repo, 20_190_711_132_100, Guard.Repo.Migrations.AddRegisteredAt)
  end
end
