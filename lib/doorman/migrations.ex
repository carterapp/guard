defmodule Doorman.Migrations do

  def run() do
    Ecto.Migrator.up(Doorman.Repo, 20160226111455, Doorman.Repo.Migrations.CreateUser)
    Ecto.Migrator.up(Doorman.Repo, 20160530004942, Doorman.Repo.Migrations.CreateDevice)
    Ecto.Migrator.up(Doorman.Repo, 20171010000000, Doorman.Repo.Migrations.AddPin)
    Ecto.Migrator.up(Doorman.Repo, 20180131210142, Doorman.Repo.Migrations.AddMobile)
    Ecto.Migrator.up(Doorman.Repo, 20180516143801, Doorman.Repo.Migrations.ModifyUserPin)
  end

end
  
