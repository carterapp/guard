defmodule Guard.Controller.ActiveSession do
  use Phoenix.Controller
  alias Guard.{Controller, Session}
  import Guard.Controller, only: [send_error: 3]

  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})

  def call(conn, opts) do
    try do
      super(conn, opts)
    rescue
      error -> send_error(conn, error, :internal_server_error)
    end
  end

  def show(conn, _) do
    case Session.current_session(conn) do
      {:ok, session} ->
        conn
        |> put_status(:ok)
        |> json(session)

      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> Controller.send_error(reason)
    end
  end
end
