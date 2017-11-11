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
