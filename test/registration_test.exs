defmodule Guard.RegistrationTest do
  use Guard.ModelCase
  use Plug.Test
  import Guard.RouterTestHelper
  alias Guard.{Router, Authenticator, Users, Session}

  defp get_body(response) do
    Jason.decode!(response.resp_body)
  end

  defp get_jwt(reponse) do
    get_body(reponse)["jwt"]
  end

  test 'registering user' do
    response = send_json(:post, "/guard/registration", %{"user" => %{"username" => "testuser"}})
    assert response.status == 201
  end

  test 'registering by email jwt' do
    response =
      send_json(:post, "/guard/registration", %{"user" => %{"email" => "test@example.com"}})

    assert response.status == 201

    assert nil == Users.get_by_confirmed_email("test@example.com")
    user = %{requested_email: "test@example.com"} = Users.get_by_email("test@example.com")

    {:ok, jwt, claims} = Authenticator.generate_login_claim(user)
    response = send_json(:get, "/guard/session/" <> jwt)
    assert response.status == 201

    %{email: "test@example.com", requested_email: nil} =
      Users.get_by_confirmed_email("test@example.com")
  end

  test 'registering by email pin' do
    response =
      send_json(:post, "/guard/registration", %{"user" => %{"email" => "test@example.com"}})

    assert response.status == 201

    assert nil == Users.get_by_confirmed_email("test@example.com")
    user = %{requested_email: "test@example.com"} = Users.get_by_email("test@example.com")

    {:ok, pin, user} = Authenticator.generate_email_pin(user)
    {:ok, user1} = Session.authenticate(%{"email" => user.requested_email, "pin" => pin})

    %{email: "test@example.com", requested_email: nil} =
      Users.get_by_confirmed_email("test@example.com")
  end

  test 'registering by mobile' do
    response = send_json(:post, "/guard/registration", %{"user" => %{"mobile" => "5554221"}})
    assert response.status == 201

    assert nil == Users.get_by_confirmed_mobile("5554221")
    user = %{requested_mobile: "5554221"} = Users.get_by_mobile("5554221")

    {:ok, pin, user} = Authenticator.generate_pin(user)
    {:ok, user1} = Session.authenticate(%{"mobile" => user.requested_mobile, "pin" => pin})

    %{mobile: "5554221", requested_mobile: nil} =
      Users.get_by_confirmed_mobile(user.requested_mobile)
  end

  test 'registering admin user' do
    response =
      send_json(:post, "/guard/registration", %{
        "user" => %{"username" => "testuser", "password" => "testuser"}
      })

    assert response.status == 201

    jwt = Jason.decode!(response.resp_body)["jwt"]
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

    response =
      send_json(:post, "/guard/session", %{
        "session" => %{"username" => "testuser", password: "testuser"}
      })

    assert response.status == 201
    jwt = Jason.decode!(response.resp_body)["jwt"]

    response = send_auth_json(:get, "/jeeves/users", jwt)
    assert response.status == 200
  end

  test 'registering same user twice' do
    response = send_json(:post, "/guard/registration", %{"user" => %{"username" => "testuser"}})
    assert response.status == 201

    response = send_json(:post, "/guard/registration", %{"user" => %{"username" => "testuser"}})
    assert response.status == 422
  end

  test 'short password' do
    response =
      send_json(:post, "/guard/registration", %{
        "user" => %{"username" => "testuser", "password" => "1"}
      })

    assert response.status == 422

    assert %{"error" => %{"password" => ["should be at least 6 character(s)"]}} ==
             get_body(response)
  end

  test 'registering untrimmed user' do
    response =
      send_json(:post, "/guard/registration", %{
        "user" => %{"username" => " tesTuser ", password: "secret"}
      })

    assert response.status == 201

    response = send_json(:post, "/guard/registration", %{"user" => %{"username" => "testuser"}})
    assert response.status == 422
    assert %{"error" => %{"username" => ["username_taken"]}} == get_body(response)

    response =
      send_json(:post, "/guard/session", %{
        "session" => %{"username" => "testuser", password: "secret"}
      })

    assert response.status == 201

    response =
      send_json(:post, "/guard/session", %{
        "session" => %{"username" => " testuser  ", password: "secret"}
      })

    assert response.status == 201
  end

  test 'registering user and dropping account' do
    response =
      send_json(:post, "/guard/registration", %{
        "user" => %{"username" => "testuser", password: "secret"}
      })

    assert response.status == 201

    response =
      send_json(:post, "/guard/session", %{
        "session" => %{"username" => "testuser", password: "secret"}
      })

    assert response.status == 201

    response =
      send_json(:post, "/guard/session", %{
        "session" => %{"username" => "TESTuser", password: "secret"}
      })

    assert response.status == 201

    json_body = Jason.decode!(response.resp_body)

    response = send_json(:delete, "/guard/account")
    assert response.status == 403

    device = %{"device" => %{token: "magic", platform: "android"}}
    response = send_json(:post, "/guard/registration/device", device)

    response =
      send_auth_json(:post, "/guard/registration/device", Map.get(json_body, "jwt"), device)

    assert response.status == 201

    response = send_auth_json(:delete, "/guard/account", Map.get(json_body, "jwt"))
    assert response.status == 200
  end

  test 'account attributes' do
    {:ok, user, jwt, _} = Guard.Authenticator.create_user_by_username("admin", "admin1")

    response = send_auth_json(:post, "/guard/account/attributes", jwt, %{someAttribute: "tester"})
    assert response.status == 200

    u1 = Guard.Users.get_by_username!("admin")
    assert %{"someAttribute" => "tester"} == u1.attrs

    response =
      send_auth_json(:post, "/guard/account/attributes", jwt, %{anotherAttribute: "test"})

    u2 = Guard.Users.get_by_username!("admin")
    assert %{"someAttribute" => "tester", "anotherAttribute" => "test"} == u2.attrs
  end

  @tag switch_user: true
  test 'switch user' do
    {:ok, admin, _, _} = Guard.Authenticator.create_user_by_username("admin", "admin123")
    {:ok, admin} = admin |> Guard.Authenticator.add_perms(%{system: [:switch_user]})
    {:ok, user, _, _} = Guard.Authenticator.create_user_by_username("user", "user12")
    assert admin.username == "admin"
    {:ok, admin_jwt, _} = Authenticator.generate_access_claim(admin)

    response = send_auth_json(:put, "/guard/session/switch/username/user", admin_jwt)
    assert response.status == 201
    assert %{"user" => %{"username" => "user"}} = get_body(response)
    user_jwt = get_jwt(response)

    response1 = send_auth_json(:put, "/guard/session/switch/username/user", user_jwt)
    assert response1.status == 401
    # refresh token
    response2 = send_auth_json(:post, "/guard/session/", user_jwt)
    user_jwt2 = get_jwt(response2)
    assert user_jwt != user_jwt2
    assert %{"user" => %{"username" => "user"}} = get_body(response2)

    response3 = send_auth_json(:delete, "/guard/session/switch", user_jwt2)
    assert response3.status == 201
    assert %{"user" => %{"username" => "admin"}} = get_body(response3)
  end

  test 'confirm email and mobile' do
    new_email = "metoo@nowhere.com"
    {:ok, user, _jwt, _resp} = Authenticator.create_user_by_email("me@nowhere.com")
    {:ok, user} = Authenticator.request_email_change(user, new_email)
    assert user.requested_email == new_email
    assert user.email != new_email

    {:ok, jwt, claims} = Authenticator.generate_login_claim(user, new_email)

    response = send_json(:get, "/guard/session/" <> jwt)
    assert response.status == 201

    user = Guard.Users.get(user.id)
    assert user.requested_email == nil
    assert user.email == new_email

    jwt = Jason.decode!(response.resp_body) |> Map.get("jwt")
    {:ok, claims} = Guard.Jwt.decode_and_verify(jwt)

    assert Map.get(claims, "typ") == "access"

    {:ok, user} = Authenticator.request_email_change(user, "another@example.com")
    {:ok, jwt, claims} = Authenticator.generate_login_claim(user, new_email)
    response = send_json(:get, "/guard/session/" <> jwt)
    assert response.status == 201

    user1 = Guard.Users.get(user.id)
    # Only update email if requested change and token match
    assert user.requested_email == user1.requested_email
    assert user.email == user1.email

    {:ok, jwt, claims} = Authenticator.generate_login_claim(user)
    response = send_json(:get, "/guard/session/" <> jwt)
    assert response.status == 201

    user1 = Guard.Users.get(user.id)
    assert nil == user1.requested_email
    assert user.requested_email == user1.email

    {:ok, user} = Authenticator.request_mobile_change(user, "5551234")
    {:ok, pin, user} = Authenticator.generate_pin(user)
    assert user.mobile == nil
    assert user.requested_mobile == "5551234"
    {:error, _} = Session.authenticate(%{"mobile" => "5551234", "pin" => "bad"})
    assert user.mobile == nil
    assert user.requested_mobile == "5551234"
    {:ok, updated_user} = Session.authenticate(%{"mobile" => "5551234", "pin" => pin})
    assert updated_user.mobile == "5551234"
    assert updated_user.requested_mobile == nil

    {:ok, user} = Authenticator.request_email_change(user, "newone@tester.dk")
    {:ok, pin, user} = Authenticator.generate_email_pin(user)
    assert user.email == new_email
    assert user.requested_email == "newone@tester.dk"
    {:error, _} = Session.authenticate(%{"email" => "newone@tester.dk", "pin" => "badtoo"})
    assert user.email == new_email
    assert user.requested_email == "newone@tester.dk"
    {:ok, updated_user} = Session.authenticate(%{"email" => "newone@tester.dk", "pin" => pin})
    assert updated_user.email == "newone@tester.dk"
    assert updated_user.requested_email == nil
  end

  test 'hash_values' do
    {:ok, user, _jwt, _resp} = Authenticator.create_user_by_email("me@nowhere.com")

    {:ok, user} = Users.update_user(user, %{pin: "1234", password: "test12"})

    assert user.enc_pin != nil

    assert user.enc_password != nil
  end

  test 'validating user user' do
    response = send_json(:get, "/guard/session")
    assert response.status == 403

    response =
      send_json(:post, "/guard/registration", %{
        "user" => %{
          "username" => "august",
          password: "not_very_secret",
          password_confirmation: "not the same"
        }
      })

    assert response.status == 422
    assert %{"error" => %{"password_confirmation" => ["password_mismatch"]}} == get_body(response)

    response =
      send_json(:post, "/guard/registration", %{
        "user" => %{
          "username" => "august",
          mobile: "+4512345678",
          email: "test@test.dk",
          email: "jalp@codenaut.com",
          password: "not_very_secret"
        }
      })

    assert response.status == 201

    response = send_json(:post, "/guard/registration/link?username=august")
    assert response.status == 200

    response =
      send_json(:post, "/guard/session", %{
        "session" => %{"username" => "august", password: "not_very_secret"}
      })

    assert response.status == 201
    json_body = Jason.decode!(response.resp_body)
    response = send_auth_json(:get, "/guard/session", Map.get(json_body, "jwt"))
    assert response.status == 200
    %{"user" => user_resp} = get_body(response)
    assert user_resp["enc_password"] == nil
    assert user_resp["password"] == nil
    assert user_resp["pin"] == nil

    response = send_auth_json(:get, "/guard/session", Map.get(json_body, "jwt") <> "bad")
    assert response.status == 401

    response =
      send_json(:post, "/guard/session", %{
        "session" => %{"username" => "august", password: "not_very_secret_and_bad"}
      })

    assert response.status == 401
  end

  test 'registering empty' do
    response = send_json(:post, "/guard/registration", %{"user" => %{}})
    assert response.status == 422
    assert %{"error" => %{"username" => ["can't be blank"]}} == get_body(response)
  end

  test 'registering bad username' do
    response = send_json(:post, "/guard/registration", %{"user" => %{"username" => ""}})
    assert response.status == 422
    assert %{"error" => %{"username" => ["can't be blank"]}} == get_body(response)
  end

  test 'password and other things' do
    response = send_json(:post, "/guard/registration/reset?username=a_user")
    assert response.status == 200

    response = send_json(:post, "/guard/registration/link?username=a_user")
    assert response.status == 200

    response = send_json(:post, "/guard/registration/link?email=createondemand@codenaut.com")
    assert response.status == 201
  end

  test 'update password normal' do
    response =
      send_json(:post, "/guard/registration", %{
        "user" => %{"username" => "new_user", password: "not_very_secret"}
      })

    assert response.status == 201

    json_body = get_body(response)
    jwt = Map.get(json_body, "jwt")

    response =
      send_auth_json(:put, "/guard/account/password", jwt, %{
        password: "not_very_secret",
        new_password: "testing",
        new_password_confirmation: "testing"
      })

    assert response.status == 200

    # Unless we have a password_reset typed token, require the old password
    response =
      send_auth_json(:put, "/guard/account/password", jwt, %{
        new_password: "testing",
        new_password_confirmation: "testing"
      })

    assert response.status == 422
    assert %{"error" => "bad_claim"} == get_body(response)

    response =
      send_auth_json(:put, "/guard/account/password", jwt, %{
        password: "not_very_secret",
        new_password: "testing",
        new_password_confirmation: "not_testing"
      })

    assert response.status == 422
    assert %{"error" => "wrong_password"} == get_body(response)

    response =
      send_json(:post, "/guard/session", %{
        "session" => %{"username" => "new_user", password: "not_the_right_one"}
      })

    assert response.status == 401

    response =
      send_json(:post, "/guard/session", %{
        "session" => %{"username" => "new_user", password: "testing"}
      })

    assert response.status == 201

    # password_reset token
    user = Users.get_by_username("new_user")
    {:ok, resetToken, _claims} = Authenticator.generate_password_reset_claim(user)

    response =
      send_auth_json(:put, "/guard/account/password", resetToken, %{
        new_password: "testing",
        new_password_confirmation: "testing"
      })

    assert response.status == 200

    response =
      send_auth_json(:put, "/guard/account/password", resetToken, %{
        new_password: "testing",
        new_password_confirmation: "testing_blah"
      })

    assert response.status == 422
  end

  @tag pin_support: true
  test 'pin login' do
    response =
      send_json(:post, "/guard/registration", %{
        "user" => %{"username" => "new_user", "mobile" => "4512345678"}
      })

    user = Users.get_by_username!("new_user")

    assert abs(
             (DateTime.utc_now() |> DateTime.to_unix()) + 60 * 60 -
               (user.email_pin_expiration |> DateTime.to_unix())
           ) <= 1

    assert user.enc_email_pin
    assert !user.enc_pin

    response = send_json(:post, "/guard/session", %{"username" => "new_user", "pin" => "badone"})

    assert response.status == 401
    assert %{"error" => "wrong_pin"} = get_body(response)

    user = Users.get_by_username!("new_user")
    {:ok, pin, user} = Authenticator.generate_pin(user)
    response = send_json(:post, "/guard/session", %{"username" => "new_user", "pin" => pin})

    assert response.status == 201

    response = send_json(:post, "/guard/session", %{"mobile" => "4512345678", "pin" => pin})

    assert response.status == 401
    assert %{"error" => "no_pin"} = get_body(response)

    {:ok, pin, user} = Authenticator.generate_pin(user, DateTime.from_unix!(0))
    response = send_json(:post, "/guard/session", %{"mobile" => "4512345678", "pin" => pin})

    assert response.status == 401
    assert %{"error" => "pin_expired"} = get_body(response)
  end

  test 'pin support' do
    response =
      send_json(:post, "/guard/registration", %{
        "user" => %{"username" => "new_user", mobile: "5551234", password: "not_very_secret"}
      })

    assert response.status == 201

    user = Users.get_by_username("new_user")
    {:ok, user} = Authenticator.clear_email_pin(user)
    {:ok, pin, user} = Authenticator.generate_pin(user)

    assert user.enc_pin != nil
    assert pin != nil
    assert user.mobile == nil
    assert user.requested_mobile == "5551234"

    response =
      send_json(:put, "/guard/account/setpassword", %{
        mobile: "5551234",
        pin: pin,
        new_password: "testing",
        new_password_confirmation: "testing"
      })

    assert response.status == 200

    user = Users.get!(user.id)
    assert user.mobile == "5551234"
    assert user.requested_mobile == nil

    response =
      send_json(:put, "/guard/account/setpassword", %{
        username: "new_user",
        pin: pin,
        new_password: "testing",
        new_password_confirmation: "testing"
      })

    assert response.status == 422
    assert %{"error" => "no_pin"} = get_body(response)

    {:ok, pin, user} = Authenticator.generate_pin(user)
    assert Guard.User.check_pin(user, pin)

    mismatch_response =
      send_json(:put, "/guard/account/setpassword", %{
        username: "new_user",
        pin: pin,
        new_password: "testing",
        new_password_confirmation: "testing_blah"
      })

    assert mismatch_response.status == 422

    assert %{"error" => %{"password_confirmation" => ["password_mismatch"]}} =
             get_body(mismatch_response)

    response =
      send_json(:put, "/guard/account/setpassword", %{
        username: "new_user",
        pin: "bad_pin",
        new_password: "testing",
        new_password_confirmation: "testing"
      })

    assert response.status == 422
    assert %{"error" => "wrong_pin"} = get_body(response)

    response =
      send_json(:put, "/guard/account/setpassword", %{
        username: "new_user",
        pin: pin,
        new_password: "testing",
        new_password_confirmation: "testing"
      })

    assert response.status == 200
  end
end
