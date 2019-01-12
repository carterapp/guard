defmodule Guard.ErrorHandler do
  import Plug.Conn
  import Guard.Controller, only: [json: 2]
  alias Guard.Controller

  # Guardian's ensure_authenticated sends :unauthenticated for 403, but Plug.Status
  # expects :forbidden
  def auth_error(conn, {:unauthenticated, reason}, _opts) do
    conn
    |> put_status(:forbidden)
    |> json(%{error: :forbidden, reason: Controller.translate_error(reason)})
  end

  def auth_error(conn, {:invalid_token, reason}, _opts) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: :invalid_token, reason: Controller.translate_error(reason)})
  end

  def auth_error(conn, {type, reason}, _opts) do
    conn
    |> put_status(type)
    |> json(%{error: type, reason: Controller.translate_error(reason)})
  end
end
