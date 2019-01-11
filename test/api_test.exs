defmodule Guard.APITest do
  use Guard.ModelCase
  use Plug.Test
  import Guard.RouterTestHelper
  alias Guard.{Users, Authenticator, Session}

  defp get_body(response) do
    Jason.decode!(response.resp_body)
  end

  @tag admin: true
  test 'admin test' do
    perms = %{system: [:read, :write]}
    {:ok, user, user_jwt, _} = Authenticator.create_user_by_username("a_user", "test123")
    {:ok, user, user_jwt, _} = Authenticator.create_user_by_username("b_user", "test123")
    {:ok, user} = Authenticator.add_perms(user, perms)
    {:ok, jwt, _claims} = Authenticator.generate_access_claim(user)

    resp = send_auth_json("get", "/jeeves/users/username/no_user", jwt)
    assert resp.status == 404

    resp = send_auth_json("get", "/jeeves/users/username/b_user", jwt)
    assert resp.status == 200
    b1 = get_body(resp)
    %{"username" => "b_user", "id" => b_id} = b1

    resp = send_auth_json("get", "/jeeves/users", jwt)
    %{"data" => [u1, u2]} = get_body(resp)
    assert u1["username"] == "a_user"
    assert u2["username"] == "b_user"

    resp =
      send_auth_json("post", "/jeeves/users", jwt, %{
        user: %{username: "c_user", password: "test123"}
      })

    c1 = get_body(resp)
    %{"username" => "c_user", "id" => c_id} = c1

    resp = send_auth_json("put", "/jeeves/users/#{c_id}", jwt, %{user: %{fullname: "User C"}})
    c1 = get_body(resp)
    %{"username" => "c_user", "fullname" => "User C"} = c1

    resp = send_auth_json("get", "/jeeves/users?direction=desc", jwt)
    %{"data" => [u1, u2, u3]} = get_body(resp)
    assert u1["username"] == "c_user"
    assert u2["username"] == "b_user"
    assert u3["username"] == "a_user"

    resp = send_auth_json("get", "/jeeves/users?direction=desc&limit=1", jwt)
    %{"data" => [u1]} = get_body(resp)
    assert u1["username"] == "c_user"

    resp = send_auth_json("get", "/jeeves/users?direction=desc&limit=1&key_inserted_at", jwt)
    %{"data" => [u1]} = get_body(resp)
    assert u1["username"] == "c_user"

    resp =
      send_auth_json(
        "get",
        "/jeeves/users?direction=desc&limit=1&key_inserted_at&start_key=c_user",
        jwt
      )

    %{"data" => [u1]} = get_body(resp)
    assert u1["username"] == "b_user"

    resp = send_auth_json("get", "/jeeves/users/#{b_id}", jwt)
    assert b1 == get_body(resp)

    resp = send_auth_json("delete", "/jeeves/users/#{b_id}", jwt)
    assert resp.status == 204

    resp = send_auth_json("delete", "/jeeves/users/#{b_id}", jwt)
    assert resp.status == 404

    resp = send_auth_json("get", "/jeeves/users", jwt)
    %{"data" => [u1, u3]} = get_body(resp)
    assert u1["username"] == "a_user"
    assert u3["username"] == "c_user"
  end

  @tag api: true
  test 'basic api test' do
    perms = %{system: [:read, :write]}
    {:ok, user, user_jwt, _} = Authenticator.create_user_by_username("a_user", "test123")
    {:ok, user} = Authenticator.add_perms(user, perms)
    {:ok, jwt, _claims} = Authenticator.generate_access_claim(user)

    {:ok, user_key} = Authenticator.create_api_key(user)
    {:ok, key} = Authenticator.create_api_key(user, perms)

    response = send_auth_json("get", "/guard/session", user_jwt)
    assert response.status == 200
    jwt_body = response |> get_body
    %{"user" => %{"username" => "a_user"}} = jwt_body

    response = send_auth_json("get", "/jeeves/users", user_jwt)
    assert response.status == 401

    response = send_auth_json("get", "/jeeves/users", jwt)
    assert response.status == 200

    response = send_app_json("get", "/guard/session", user_key.key)
    assert response.status == 200
    app_body = response |> get_body
    %{"user" => %{"username" => "a_user"}} = app_body

    response = send_app_json("get", "/jeeves/users", user_key.key)
    assert response.status == 401

    response = send_app_json("get", "/jeeves/users", key.key)
    assert response.status == 200

    assert {:ok, %{"sub" => sub}} = Guard.ApiKey.revoke(user_key.key)
    assert sub == "key:#{user_key.id}"

    response = send_app_json("get", "/guard/session", user_key.key)
    assert response.status == 401

    response = send_app_json("delete", "/guard/session", key.key)
    assert response.status == 200

    response = send_app_json("get", "/jeeves/users", key.key)
    assert response.status == 401
  end

  @tag api: true
  test 'web test' do
    {:ok, user, jwt, _} = Authenticator.create_user_by_username("a_user", "test123")
    {:ok, user2, jwt2, _} = Authenticator.create_user_by_username("b_user", "test123")

    response = send_auth_json("get", "/guard/keys", jwt)
    assert response.status == 200
    assert [] == get_body(response)

    response = send_auth_json("post", "/guard/keys", jwt)
    key = get_body(response)
    assert Enum.empty?(key["permissions"])

    response = send_auth_json("get", "/guard/keys", jwt)
    assert response.status == 200
    [k] = get_body(response)
    assert k == key

    response = send_auth_json("post", "/guard/keys", jwt2)
    user2_key = get_body(response)

    response = send_auth_json("get", "/guard/keys", jwt2)
    assert response.status == 200
    [k] = get_body(response)
    assert k == user2_key

    response = send_auth_json("post", "/guard/keys", jwt, %{permissions: %{system: [:read]}})
    key2 = get_body(response)
    assert key2["permissions"] == %{"system" => ["read"]}

    response = send_auth_json("get", "/guard/keys", jwt)
    assert response.status == 200
    [k1, k2] = get_body(response)
    assert k1 == key || k2 == key
    assert k1 == key2 || k2 == key2
    assert k1["key"] != k2["key"]

    response = send_app_json("get", "/guard/session", key["key"])
    assert response.status == 200

    response = send_app_json("get", "/jeeves/users", key["key"])
    assert response.status == 401

    response = send_app_json("get", "/guard/session", key2["key"])
    assert response.status == 200

    response = send_app_json("get", "/jeeves/users", key2["key"])
    assert response.status == 401

    response =
      send_auth_json("post", "/guard/keys", jwt, %{permissions: %{system: [:read, :write]}})

    key3 = get_body(response)

    response = send_app_json("get", "/jeeves/users", key3["key"])
    assert response.status == 200

    encoded_key = URI.encode_www_form(key["key"])
    response = send_auth_json("delete", "/guard/keys/#{encoded_key}", jwt)
    assert response.status == 200

    response = send_app_json("get", "/guard/session", key["key"])
    assert response.status == 401

    encoded_key = URI.encode_www_form(key["key"])
    response = send_auth_json("delete", "/guard/keys/#{encoded_key}", jwt)
    assert response.status == 404

    response = send_app_json("get", "/guard/session", user2_key["key"])
    assert response.status == 200

    encoded_key = URI.encode_www_form(key2["key"])
    response = send_auth_json("delete", "/guard/keys/#{encoded_key}", jwt)
    assert response.status == 200

    response = send_auth_json("get", "/guard/keys", jwt2)
    assert response.status == 200
    [k] = get_body(response)
    assert k == user2_key

    response = send_auth_json("get", "/guard/keys", jwt)
    assert response.status == 200
    [k] = get_body(response)
    assert k == key3
  end
end
