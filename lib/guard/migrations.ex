defmodule Guard.Migrations do

  def run(repo) do
    Ecto.Migrator.up(repo, 20160226111455, Guard.Repo.Migrations.CreateUser)
    Ecto.Migrator.up(repo, 20160530004942, Guard.Repo.Migrations.CreateDevice)
    Ecto.Migrator.up(repo, 20171010000000, Guard.Repo.Migrations.AddPin)
    Ecto.Migrator.up(repo, 20180131210142, Guard.Repo.Migrations.AddMobile)
    Ecto.Migrator.up(repo, 20180516143801, Guard.Repo.Migrations.ModifyUserPin)
  end

end
  
