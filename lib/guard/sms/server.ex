defmodule Guard.Sms.Server do
  @moduledoc false
  use GenServer
  use Tesla
  # Hackney does not play well with gatewayapi.com
  adapter(Tesla.Adapter.Httpc)

  def start_link(name, config) do
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def send_message(pid, recipients, message, callback) do
    GenServer.cast(pid, {:message, recipients, message, callback})
  end

  def status(pid) do
    GenServer.call(pid, {:status})
  end

  ## GenServer Callbacks

  def init(config) do
    client =
      Tesla.client([
        {Tesla.Middleware.BaseUrl, "https://gatewayapi.com/rest"},
        {Tesla.Middleware.BasicAuth, [{:username, config[:token] || ""}]},
        Tesla.Middleware.JSON
      ])

    {:ok, %{options: config[:options], client: client}}
  end

  def handle_call({:status}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_cast({:message, recipients, message, callback}, state) do
    resp =
      try do
        recip =
          if is_list(recipients) do
            recipients
          else
            [recipients]
          end

        recip = Enum.map(recip, fn r -> %{msisdn: r} end)

        payload =
          if is_map(message) do
            Map.put(message, :recipients, recip)
          else
            %{recipients: recip, message: message}
          end

        do_post(state.client, state.options, payload)
      rescue
        error -> {:error, error}
      end

    if !is_nil(callback) do
      callback.(resp)
    end

    {:noreply, state, :hibernate}
  end

  defp do_post(client, options, payload) do
    msg = Map.merge(options, payload)
    post!(client, "/mtsms", msg)
  end
end
