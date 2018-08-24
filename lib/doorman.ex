defmodule Doorman do
  require Logger
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    Logger.info "Waking up Doorman"
    {children, doorman_started} = 
      if Application.get_env(:doorman, Doorman.Repo) do
        {[ # Start the Ecto repository
          supervisor(Doorman.Repo, []),
        ], true}
      else
        {[], false}
      end

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
    
    if ok && doorman_started do 
      Doorman.Migrations.run()
    end

    {ok, sup_pid}
  end
end
