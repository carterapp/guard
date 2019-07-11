defmodule Guard.Pusher.Server do
  @moduledoc false
  use GenServer
  use Tesla
  adapter(Tesla.Adapter.Hackney)

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
    client =
      Tesla.client([
        {Tesla.Middleware.BaseUrl, "https://fcm.googleapis.com/fcm"},
        {Tesla.Middleware.Headers, [{"Authorization", "key=" <> (config[:key] || "")}]},
        Tesla.Middleware.JSON
      ])

    {:ok, %{options: config[:options], client: client}}
  end

  def handle_call({:status}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  defp update_last_sent(device) do
    device
    |> Guard.Device.changeset(%{last_sent: DateTime.utc_now()})
    |> Repo.update()
  end

  defp send_notification_payload(client, device, message, options) do
    try do
      resp = do_post(client, options, Map.merge(message, %{to: device.token}))

      if resp.body != nil do
        if resp.body["failure"] == 1 do
          Guard.Repo.delete(device)
        end
      end

      update_last_sent(device)

      resp
    rescue
      error -> {:error, error}
    end
  end

  def handle_cast({:user, user, message, callback}, state) do
    devices = Guard.Users.list_devices(user) || []

    Enum.each(devices, fn d ->
      resp = send_notification_payload(state.client, d, message, state.options)

      if !is_nil(callback) do
        callback.(resp)
      end
    end)

    {:noreply, state, :hibernate}
  end

  def handle_cast({:message, message, callback}, state) do
    resp =
      try do
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
