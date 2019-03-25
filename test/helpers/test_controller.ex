defmodule(Guard.Test.Controller) do
  @moduledoc false
  use Guard.Controller

  def context_test(conn, _) do
    user = Guard.Authenticator.authenticated_user!(conn)

    conn
    |> json(user.context)
  end
end
