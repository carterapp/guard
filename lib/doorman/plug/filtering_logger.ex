defmodule Doorman.Plug.FilteringLogger do
  @moduledoc """
  A plug for logging basic request information in the format with a filtering option:
      GET /index.html
      Sent 200 in 572ms
  To use it, just plug it into the desired module.
      plug Plug.Logger, log: :debug, filter: fn(conn)->should_log?(conn)end
  ## Options
    * `:log` - The log level at which this plug should log its request info.
      Default is `:info`.
    * `:filter` - if provided and returns falseish, do not log request.
  """

  require Logger
  alias Plug.Conn
  @behaviour Plug

  def init(opts) do
    [level: Keyword.get(opts, :log, :info), filter: opts[:filter]]
  end

  def call(conn, opts) do
    level = opts[:level]
    filter = opts[:filter]
    if !filter || filter.(conn) do
      Plug.Logger.call(conn, level)
    end
  end

end
