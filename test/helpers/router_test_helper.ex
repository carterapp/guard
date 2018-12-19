defmodule Guard.RouterTestHelper do
  use Plug.Test
  alias Guard.Router
  @opts Router.init([])


  def send_auth_json(method, url, token, body \\ nil, headers \\ []) do
    send_json(method, url, body, [{"authorization", "Bearer " <> token} | headers])
  end

  def send_app_json(method, url, app_key, body \\ nil, headers \\ []) do
    send_json(method, url, body, [{"authorization", "Key "<> app_key} | headers])
  end

  def send_json(method, url, body \\ nil, headers \\ []) do
    send_request(method, url, body, [{"content-type", "application/json"} | headers])

  end

  def send_request(method, url, body \\ nil, headers \\ []) do
    conn = conn(method, url, Jason.encode!(body))
    conn = Enum.reduce(headers, conn, fn ({name, value}, conn) ->
      put_req_header(conn, name, value)
    end)

  conn
  |> Plug.Conn.fetch_query_params
  |> Router.call(@opts)
  end

end
