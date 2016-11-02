defmodule Doorman do
  require Logger
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    Logger.info "Waking up doorman"
    children = [
      # Start the Ecto repository
      supervisor(Doorman.Repo, []),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Doorman.Supervisor]
    {ok, sup_pid} = Supervisor.start_link(children, opts)
    
    if ok do 
      Ecto.Migrator.up(Doorman.Repo, 20160226111455, Doorman.Repo.Migrations.CreateUser)
      Ecto.Migrator.up(Doorman.Repo, 20160530004942, Doorman.Repo.Migrations.CreateDevice)
    end

    {ok, sup_pid}

    
  end
end
