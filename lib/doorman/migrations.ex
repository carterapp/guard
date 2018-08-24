defmodule Doorman.Migrations do

  def run(repo) do
    Ecto.Migrator.up(repo, 20160226111455, Doorman.Repo.Migrations.CreateUser)
    Ecto.Migrator.up(repo, 20160530004942, Doorman.Repo.Migrations.CreateDevice)
    Ecto.Migrator.up(repo, 20171010000000, Doorman.Repo.Migrations.AddPin)
    Ecto.Migrator.up(repo, 20180131210142, Doorman.Repo.Migrations.AddMobile)
    Ecto.Migrator.up(repo, 20180516143801, Doorman.Repo.Migrations.ModifyUserPin)
  end

end
  
