defmodule Doorman.Pusher.Server do
  use GenServer
  use Tesla
  import Ecto.Query
  adapter Tesla.Adapter.Hackney

  def start_link(name, config) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def send_user_message(pid, user, message, callback) do
    GenServer.cast(pid, {:user, user, message, callback})
  end

  def send_message(pid, message, callback) do
    GenServer.cast(pid, {:message, message, callback})
  end

  def status(pid) do
    GenServer.call(pid, {:status})
  end

  ## GenServer Callbacks

  def init(config) do
    client = Tesla.build_client [
      {Tesla.Middleware.BaseUrl, "https://fcm.googleapis.com/fcm"},
      {Tesla.Middleware.Headers, [{"Authorization", "key=" <> (config[:key] || "") }]},
      Tesla.Middleware.JSON
    ]
    {:ok, %{options: config[:options], client: client}}
  end

  def handle_call({:status}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_cast({:user, user, message, callback}, state) do
    devices = Doorman.Users.list_devices(user)
    if length(devices) > 0 do
      Enum.each(devices, fn(d) -> 
        resp = try do
          resp = do_post(state.client, state.options, Map.merge(message, %{to: d.token}))
          if resp.body != nil do
            if resp.body["failure"] == 1 do
              Doorman.Repo.delete(d)
            end
          end
          resp
        rescue 
          error -> {:error, error}
        end
        if !is_nil(callback) do
          callback.(resp)
        end
     end)
    end
    {:noreply, state, :hibernate}
  end

  def handle_cast({:message, message, callback}, state) do
    resp = try do
       do_post(state.client, state.options, message)
    rescue 
      error -> {:error, error}
    end 

    if !is_nil(callback) do
      callback.(resp)
    end
    {:noreply, state, :hibernate}
  end

  defp do_post(client, options, message) do
    msg = Map.merge(options, message)
    post!(client, "/send", msg)
  end

end
