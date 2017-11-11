defmodule Doorman.Plug.AuditLogger do
  @moduledoc """
    Attached metadata to Logger for audit logging
  """

  require Logger
  alias Doorman.Authenticator
  @behaviour Plug

  def init(opts) do
    Keyword.get(opts, :log, :info)
  end

  def call(conn, _level) do
    remote_ip = case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [forwarded|_rest] -> forwarded
      _ -> Enum.join(Tuple.to_list(conn.remote_ip), ".")
    end
    Logger.metadata(remote_ip: remote_ip)
    case Authenticator.current_claims(conn) do
      { :ok, _claims } ->
        user = Guardian.Plug.current_resource(conn)
        Logger.metadata(user_id: user.id)
        conn
      _ -> 
        conn

    end
  end

end
