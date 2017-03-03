defmodule Doorman.Pusher.Server do
  use GenServer
  use Tesla
  require Logger

  def start_link(name, config) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def send_user_message(pid, user, message) do
    GenServer.cast(pid, {:user, user, message})
  end

  def send_message(pid, message) do
    GenServer.cast(pid, {:message, message})
  end

  def status(pid) do
    GenServer.call(pid, {:status})
  end

  ## GenServer Callbacks

  def init(config) do
    client = Tesla.build_client [
      {Tesla.Middleware.BaseUrl, "https://fcm.googleapis.com/fcm"},
      {Tesla.Middleware.Headers, %{"Authorization" => "key=" <> config[:key] }},
      Tesla.Middleware.JSON
    ]
    {:ok, %{options: config[:options], client: client}}
  end

  def handle_call({:status}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast({:user, user, message}, state) do
    devices = Doorman.Repo.all(Doorman.Device, user_id: user.id)
    if length(devices) > 0 {
      reg_ids = Enum.map(devices, fn(d) -> token end)
      do_post(state.client, state.options. Map.merge(message, %{registration_ids: reg_ids}))
    }
    {:noreply, state}
  end

  def handle_cast({:message, message}, state) do
    resp = do_post(state.client, state.options, message)
    Logger.info "#{inspect resp}"
    
    {:noreply, state}
  end

  defp do_post(client, options, message) do
    msg = Map.merge(options, message)
    post(client, "/send", msg)
  end



end
