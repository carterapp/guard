defmodule Guard do
  @moduledoc false
  require Logger
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    Logger.info("Waking up Guard")

    {children, repo_started} =
      if Application.get_env(:guard, Guard.Repo) do
        # Start the Ecto repository
        {[
           supervisor(Guard.Repo, [])
         ], true}
      else
        {[], false}
      end

    pusher_conf = Application.get_env(:guard, Guard.Pusher)

    children =
      if pusher_conf != nil do
        Logger.info("Adding Pusher supervisor")
        [supervisor(Guard.Pusher.Server, [Guard.Pusher.Server, pusher_conf]) | children]
      else
        children
      end

    sms_conf = Application.get_env(:guard, Guard.Sms)

    children =
      if sms_conf != nil do
        Logger.info("Adding SMS supervisor")
        [supervisor(Guard.Sms.Server, [Guard.Sms.Server, sms_conf]) | children]
      else
        children
      end

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Guard.Supervisor]
    {ok, sup_pid} = Supervisor.start_link(children, opts)

    if ok && repo_started do
      Guard.Migrations.run(Guard.Repo)
    end

    {ok, sup_pid}
  end
end
