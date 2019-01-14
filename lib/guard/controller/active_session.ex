defmodule Guard.Controller.ActiveSession do
  use Guard.Controller
  alias Guard.{Session}

  plug(Guardian.Plug.EnsureAuthenticated, claims: %{"typ" => "access"})

  def show(conn, _) do
    with {:ok, session} <- Session.current_session(conn) do
      conn
      |> put_status(:ok)
      |> json(session)
    end
  end
end
