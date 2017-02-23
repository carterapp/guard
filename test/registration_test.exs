defmodule Doorman.RegistrationTest do
  use Doorman.ModelCase
  use Plug.Test
  import  Doorman.RouterTestHelper
  alias Doorman.{Router, Authenticator}


  test 'registering user' do
    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "testuser"}})
    assert response.status == 201
  end

  test 'registering same user twice' do
    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "testuser"}})
    assert response.status == 201

    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "testuser"}})
    assert response.status == 422
 
  end


  test 'registering user and dropping account' do
    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "testuser", "password": "secret"}})
    assert response.status == 201

    response = send_json(:post, "/doorman/session", %{"session" => %{"username" => "testuser", "password": "secret"}})
    assert response.status == 201

    json_body = Poison.decode!(response.resp_body)

    response = send_json(:delete, "/doorman/account")
    assert response.status == 401

    device = %{"device"=> %{"token": "magic", "platform": "android"}}
    response = send_json(:post, "/doorman/registration/device", device)
    response = send_auth_json(:post, "/doorman/registration/device", Map.get(json_body, "jwt"), device)
    assert response.status == 201

    response = send_auth_json(:delete, "/doorman/account", Map.get(json_body, "jwt"))
    assert response.status == 200


  end


  test 'validating user user' do
    response = send_json(:get, "/doorman/session")
    assert response.status == 401

    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "august", "password": "not_very_secret", "password_confirmation": "not the same"}})
    assert response.status == 422

    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "august", "password": "not_very_secret"}})
    assert response.status == 201
    
    response = send_json(:post, "/doorman/session", %{"session" => %{"username" => "august", "password": "not_very_secret"}})
    assert response.status == 201

    json_body = Poison.decode!(response.resp_body)

    response = send_auth_json(:get, "/doorman/session", Map.get(json_body, "jwt"))
    assert response.status == 200

    response = send_auth_json(:get, "/doorman/session", Map.get(json_body, "jwt") <> "bad")
    assert response.status == 401

    response = send_json(:post, "/doorman/session", %{"session" => %{"username" => "august", "password": "not_very_secret_and_bad"}})
    assert response.status == 401
 
  end


  test 'registering empty' do
    response = send_json(:post, "/doorman/registration", %{"user"=> %{}})
    assert response.status == 422
  end

  test 'registering bad username' do
    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => ""}})
    assert response.status == 422
  end

  test 'password and other things' do

    response = send_json(:post, "/doorman/registration/reset?username=a_user")
    assert response.status == 200

    response = send_json(:post, "/doorman/registration/link?username=a_user")
    assert response.status == 200

  end

  test 'update password normal' do

    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "new_user", "password": "not_very_secret"}})
    assert response.status == 201

    json_body = Poison.decode!(response.resp_body)
    jwt = Map.get(json_body, "jwt")
    
    response = send_auth_json(:put, "/doorman/account/password", jwt, %{"password": "not_very_secret", "new_password": "testing", "new_password_confirmation": "testing"})
    assert response.status == 200

    #Unless we have a password_reset typed token, require the old password
    response = send_auth_json(:put, "/doorman/account/password", jwt, %{"new_password": "testing", "new_password_confirmation": "testing"})
    assert response.status == 412

    response = send_auth_json(:put, "/doorman/account/password", jwt, %{"password": "not_very_secret", "new_password": "testing", "new_password_confirmation": "not_testing"})
    assert response.status == 412

    response = send_json(:post, "/doorman/session", %{"session" => %{"username" => "new_user", "password": "not_the_right_one"}})
    assert response.status == 401
    response = send_json(:post, "/doorman/session", %{"session" => %{"username" => "new_user", "password": "testing"}})
    assert response.status == 201
    
    #password_reset token
    user =  Authenticator.get_by_username("new_user")
    {:ok, resetToken, _claims} = Authenticator.generate_password_reset_claim(user)
    response = send_auth_json(:put, "/doorman/account/password", resetToken, %{"new_password": "testing", "new_password_confirmation": "testing"})
    assert response.status == 200
    response = send_auth_json(:put, "/doorman/account/password", resetToken, %{"new_password": "testing", "new_password_confirmation": "testing_blah"})
    assert response.status == 422


  end

end
