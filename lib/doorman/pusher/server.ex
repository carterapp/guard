defmodule Doorman.Pusher.Server do
  use GenServer
  require Logger

  def start_link(name, config) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def send_user_message(pid, user, message) do
    GenServer.cast(pid, {:user, user, message})
  end

  def send_device_message(pid, token, message) do
    GenServer.cast(pid, {:device, token, message})
  end

  def send_topic_message(pid, topic, message) do
    GenServer.cast(pid, {:topic, topic, message})
  end

  def status(pid) do
    GenServer.call(pid, {:status})
  end

  ## GenServer Callbacks

  def init(config) do
    {:ok, %{config: config}}
  end

  def handle_call({:status}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast({:topic, topic, message}, state) do
    {:noreply, state}
  end

end
