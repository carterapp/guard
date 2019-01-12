defmodule Guard.Controller.ActiveSession do
  use Guard.Controller
  alias Guard.{Session}

  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})

  def call(conn, opts) do
    try do
      super(conn, opts)
    rescue
      error -> send_error(conn, error)
    end
  end

  def show(conn, _) do
    with {:ok, session} <- Session.current_session(conn) do
      conn
      |> put_status(:ok)
      |> json(session)
    end
  end
end
