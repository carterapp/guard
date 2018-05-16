defmodule Doorman do
  require Logger
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    Logger.info "Waking up Doorman"
    children = [
      # Start the Ecto repository
      supervisor(Doorman.Repo, []),
    ]

    pusher_conf = Application.get_env(:doorman, Doorman.Pusher)
    children = if pusher_conf != nil do
      Logger.info "Adding Pusher supervisor"
      [supervisor(Doorman.Pusher.Server, [Doorman.Pusher.Server, pusher_conf]) | children]
    else 
      children
    end
    sms_conf = Application.get_env(:doorman, Doorman.Sms)
    children = if sms_conf != nil do
      Logger.info "Adding SMS supervisor"
      [supervisor(Doorman.Sms.Server, [Doorman.Sms.Server, sms_conf]) | children]
    else 
      children
    end
 
    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Doorman.Supervisor]
    {ok, sup_pid} = Supervisor.start_link(children, opts)
    
    if ok do 
      Ecto.Migrator.up(Doorman.Repo, 20160226111455, Doorman.Repo.Migrations.CreateUser)
      Ecto.Migrator.up(Doorman.Repo, 20160530004942, Doorman.Repo.Migrations.CreateDevice)
      Ecto.Migrator.up(Doorman.Repo, 20171010000000, Doorman.Repo.Migrations.AddPin)
      Ecto.Migrator.up(Doorman.Repo, 20180131210142, Doorman.Repo.Migrations.AddMobile)
      Ecto.Migrator.up(Doorman.Repo, 20180516143801, Doorman.Repo.Migrations.ModifyUserPin)
    end

    {ok, sup_pid}
  end
end
