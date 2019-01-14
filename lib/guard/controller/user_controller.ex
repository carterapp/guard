defmodule Guard.Controller.UserController do
  use Guard.Controller
  alias Guard.{User, Users}

  def get_user(conn, %{"id" => id}) do
    conn
    |> json(Users.get!(id))
  end

  def get_user(conn, %{"username" => username}) do
    conn
    |> json(Users.get_by_username!(username))
  end

  def get_user(conn, %{"email" => email}) do
    conn
    |> json(Users.get_by_email!(email))
  end

  def get_user(conn, %{"mobile" => mobile}) do
    conn
    |> json(Users.get_by_mobile!(mobile))
  end

  def list_user_devices(conn, %{"user_id" => user_id}) do
    user = Users.get!(user_id)
    devices = Users.list_devices(user)

    conn
    |> json(devices)
  end

  def delete_user(conn, %{"id" => user_id}) do
    user = Users.get!(user_id)

    with {:ok, %User{}} <- Users.delete_user(user) do
      conn
      |> send_resp(:no_content, "")
    end
  end

  def update_user(conn, %{"id" => user_id, "user" => user_params}) do
    user = Users.get!(user_id)

    with {:ok, %User{} = user} <- Users.update_user(user, user_params) do
      conn
      |> json(user)
    end
  end

  def create_user(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Users.create_user(user_params) do
      conn
      |> json(user)
    end
  end

  def list_all_users(conn, params) do
    limit = Map.get(params, "limit", nil)
    start_id = Map.get(params, "start_id", nil)
    start_key = Map.get(params, "start_key", nil)

    key =
      case Map.get(params, "key", "username") do
        nil -> nil
        val -> String.to_existing_atom(val)
      end

    direction =
      case Map.get(params, "direction", "asc") do
        nil -> nil
        val -> String.to_existing_atom(val)
      end

    users =
      Users.list_users(
        limit: limit,
        start_key: start_key,
        start_id: start_id,
        key: key,
        direction: direction
      )

    conn
    |> json(%{data: users})
  end
end
