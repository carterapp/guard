defmodule Guard.ErrorHandler do
  @moduledoc false
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
    |> Guard.Jwt.Plug.sign_out(
      clear_remember_me: Application.get_env(:guard, Guard.Jwt)[:remember_user]
    )
    |> put_status(:unauthorized)
    |> json(%{error: :invalid_token, reason: Controller.translate_error(reason)})
  end

  def auth_error(conn, {type, reason}, _opts) do
    conn
    |> put_status(type)
    |> json(%{error: type, reason: Controller.translate_error(reason)})
  end
end
