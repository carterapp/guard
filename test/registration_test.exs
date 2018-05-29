defmodule Doorman.RegistrationTest do
  use Doorman.ModelCase
  use Plug.Test
  import  Doorman.RouterTestHelper
  alias Doorman.{Router, Authenticator, Users}


  test 'registering user' do
    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "testuser"}})
    assert response.status == 201
  end

  test 'registering admin user' do
    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "testuser", "password" => "testuser"}})
    assert response.status == 201

    jwt = Poison.decode!(response.resp_body)["jwt"]
    response = send_auth_json(:get, "/jeeves/users", jwt)
    assert response.status == 401

    user = Users.get_by_username!("testuser")
    assert !Authenticator.has_perms?(user, "system")
    assert !Authenticator.has_perms?(user, %{"system" => ["read", "write"]})
    Authenticator.add_perms(user, %{"system" => ["read", "write"]})
    user = Users.get_by_username!("testuser")
    assert Authenticator.has_perms?(user, "system")
    assert !Authenticator.has_perms?(user, "something")
    assert Authenticator.has_perms?(user, %{"system" => ["read", "write"]})
    assert !Authenticator.has_perms?(user, %{"something" => ["read", "write"]})
    assert !Authenticator.has_perms?(user, %{"system" => ["read", "write", "control"]})
 
    response = send_json(:post, "/doorman/session", %{"session" => %{"username" => "testuser", "password": "testuser"}})
    assert response.status == 201
    jwt = Poison.decode!(response.resp_body)["jwt"]
 
    response = send_auth_json(:get, "/jeeves/users", jwt)
    assert response.status == 200
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
    
    response = send_json(:post, "/doorman/session", %{"session" => %{"username" => "TESTuser", "password": "secret"}})
    assert response.status == 201

    json_body = Poison.decode!(response.resp_body)

    response = send_json(:delete, "/doorman/account")
    assert response.status == 403

    device = %{"device"=> %{"token": "magic", "platform": "android"}}
    response = send_json(:post, "/doorman/registration/device", device)
    response = send_auth_json(:post, "/doorman/registration/device", Map.get(json_body, "jwt"), device)
    assert response.status == 201

    response = send_auth_json(:delete, "/doorman/account", Map.get(json_body, "jwt"))
    assert response.status == 200


  end

  test 'confirm email and mobile' do

    new_email = "metoo@nowhere.com"
    {:ok, user, _jwt, _resp} = Authenticator.create_user_by_email("me@nowhere.com")
    {:ok, user} = Authenticator.change_email(user, new_email)
    assert user.requested_email == new_email
    assert user.email != new_email
  
    {:ok, jwt, claims} = Authenticator.generate_login_claim(user, new_email)

    response = send_json(:get, "/doorman/session/" <> jwt)
    assert response.status == 201


    user = Doorman.Users.get(user.id)
    assert user.requested_email == nil
    assert user.email == new_email

    jwt = Poison.decode!(response.resp_body) |> Map.get("jwt")
    {:ok, claims} = Doorman.Guardian.decode_and_verify(jwt)

    assert Map.get(claims, "typ") == "access"
 
    {:ok, user} = Authenticator.change_email(user, "another@example.com")
    {:ok, jwt, claims} = Authenticator.generate_login_claim(user, new_email)
    response = send_json(:get, "/doorman/session/" <> jwt)
    assert response.status == 201


    user1 = Doorman.Users.get(user.id)
    assert user.requested_email == user1.requested_email
    assert user.email == user1.email

    {:ok, jwt, claims} = Authenticator.generate_login_claim(user)
    response = send_json(:get, "/doorman/session/" <> jwt)
    assert response.status == 201


    user1 = Doorman.Users.get(user.id)
    assert user.requested_email == user1.requested_email
    assert user.email == user1.email



 
  end

  test 'hash_values' do
    
    {:ok, user, _jwt, _resp} = Authenticator.create_user_by_email("me@nowhere.com")

    {:ok, user} = Users.update_user(user, %{pin: "1234", password: "test12"})

    assert user.enc_pin != nil

    assert user.enc_password != nil

  end


  test 'validating user user' do
    response = send_json(:get, "/doorman/session")
    assert response.status == 403

    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "august", "password": "not_very_secret", "password_confirmation": "not the same"}})
    assert response.status == 422

    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "august", "email": "jalp@codenaut.com", "password": "not_very_secret"}})
    assert response.status == 201
    
    response = send_json(:post, "/doorman/registration/link?username=august")
    assert response.status == 200

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
    
    response = send_json(:post, "/doorman/registration/link?email=createondemand@codenaut.com")
    assert response.status == 201

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
    user =  Users.get_by_username("new_user")
    {:ok, resetToken, _claims} = Authenticator.generate_password_reset_claim(user)

    response = send_auth_json(:put, "/doorman/account/password", resetToken, %{"new_password": "testing", "new_password_confirmation": "testing"})
    assert response.status == 200
    response = send_auth_json(:put, "/doorman/account/password", resetToken, %{"new_password": "testing", "new_password_confirmation": "testing_blah"})
    assert response.status == 422


  end


  test 'pin support' do
    response = send_json(:post, "/doorman/registration", %{"user"=> %{"username" => "new_user", "password": "not_very_secret"}})
    assert response.status == 201

    user = Users.get_by_username("new_user")
    {:ok, pin, user} = Authenticator.generate_pin(user)

    assert user.enc_pin != nil
    assert pin != nil

    response = send_json(:put, "/doorman/account/setpassword", %{"username": "new_user", "pin": pin, "new_password": "testing", "new_password_confirmation": "testing"})
    assert response.status == 200

    response = send_json(:put, "/doorman/account/setpassword", %{"username": "new_user", "pin": pin, "new_password": "testing", "new_password_confirmation": "testing"})
    assert response.status == 412


    {:ok, pin, user} = Authenticator.generate_pin(user)
    response = send_json(:put, "/doorman/account/setpassword", %{"username": "new_user", "pin": pin, "new_password": "testing", "new_password_confirmation": "testing_blah"})
    assert response.status == 422

    response = send_json(:put, "/doorman/account/setpassword", %{"username": "new_user", "pin": "bad_pin", "new_password": "testing", "new_password_confirmation": "testing"})
    assert response.status == 412


    response = send_json(:put, "/doorman/account/setpassword", %{"username": "new_user", "pin": pin, "new_password": "testing", "new_password_confirmation": "testing"})
    assert response.status == 200







  end

end
