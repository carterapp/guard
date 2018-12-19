defmodule Guard.APITest do
  use Guard.ModelCase
  use Plug.Test
  import  Guard.RouterTestHelper
  alias Guard.{Users, Authenticator, Session}

  defp get_body(response) do
    Jason.decode!(response.resp_body)
  end

  @tag api: true
  test 'basic api test' do
    perms = %{system: [:read, :write]}
    {:ok, user, user_jwt, _} = Authenticator.create_user_by_username("a_user", "test123")
    {:ok, user} = Authenticator.add_perms(user, perms)
    {:ok, jwt, _claims} = Authenticator.generate_access_claim(user)

    {:ok, user_key} = Authenticator.create_api_key(user)
    {:ok, key} = Authenticator.create_api_key(user, perms)


    #response = send_auth_json("get", "/guard/session", user_jwt)
    #assert response.status == 200
    #jwt_body = response |> get_body
    #%{"user" => %{"username" => "a_user"}} = jwt_body

    #response = send_auth_json("get", "/jeeves/users", user_jwt)
    #assert response.status == 401
 
    #response = send_auth_json("get", "/jeeves/users", jwt)
    #assert response.status == 200
 
    response = send_app_json("get", "/guard/session", user_key.key)
    assert response.status == 200
    app_body = response |> get_body
    %{"user" => %{"username" => "a_user"}} = app_body

    response = send_app_json("get", "/jeeves/users", user_key.key)
    assert response.status == 401

    response = send_app_json("get", "/jeeves/users", key.key)
    assert response.status == 200

 
  end


end
