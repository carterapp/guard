defmodule Guard.AuthenticatorTest do
  use Guard.ModelCase
  alias Guard.{Authenticator, User, Users, Session}

  test "Create missing user" do
    {:error, _, _} = Authenticator.create_user(%{})
  end

  test "Create user" do
    {:ok, _, _, _} = Authenticator.create_user(%{"username" => "August"})

    {:error, %{username: ["username_taken"]}, %Ecto.Changeset{}} =
      Authenticator.create_user(%{"username" => "August"})
  end

  test "Create user with nil password" do
    {:error, %{errors: [password: {"cannot be empty", []}]}} =
      Users.create_user(%{username: "hey there"})
  end

  test "Test transactional creation" do
    extra_fn = fn user ->
      assert !is_nil(user.id)
      _ = Users.get!(user.id)
      {:ok, user, _jwt, _response} = Authenticator.create_user(%{"username" => "AugustAndre"})
      {:ok, user}
    end

    {:ok, user1, _, _} = Authenticator.create_user(%{"username" => "August"}, extra_fn)
    assert !is_nil(Users.get_by_username!("August"))
    assert !is_nil(Users.get_by_username!("AugustAndre"))

    extra_fn2 = fn user ->
      {:ok, user, _jwt, _resp} = Authenticator.create_user_by_mobile("555-121")
      assert !is_nil(Users.get_by_username("555-121"))
      {:error, :im_a_teapot}
    end

    {:error, _, :im_a_teapot} =
      Authenticator.create_user_by_username("Emilia", "badpassword", extra_fn2)

    assert is_nil(Users.get_by_username("Emilia"))
    assert is_nil(Users.get_by_username("555-512"))

    extra_fn3 = fn user ->
      {:error, _, changeset} = Authenticator.create_user_by_mobile("Emilia")
      {:error, changeset}
    end

    {:error, %{username: ["username_taken"]}, %Ecto.Changeset{}} =
      Authenticator.create_user_by_username("Emilia", "badpassword", extra_fn3)

    assert is_nil(Users.get_by_username("Emilia"))
    assert is_nil(Users.get_by_username("555-512"))
  end

  test "Test confirm by token" do
    {:ok, user} =
      Users.create_user(%{
        username: "tester",
        password: "Blahblah",
        requested_email: "fisk@example.dk"
      })

    assert user.email == nil
    assert user.requested_email == "fisk@example.dk"

    {:ok, jwt, _claims} = Authenticator.generate_login_claim(user)
    {:ok, user, _claims} = Session.authenticate_with_token(jwt)

    assert user.email == "fisk@example.dk"
    assert user.requested_email == nil
  end

  test "Create mobile user" do
    {:ok, user, _, _} = Authenticator.create_user_by_mobile("4530123456")
    {:error, _, _} = Authenticator.create_user_by_mobile("4530123456")
    {:ok, user_pin, user} = Authenticator.generate_pin(user)
    true = User.check_pin(user, user_pin)
    false = User.check_pin(user, "wrong_one")
    {:ok, user} = Authenticator.use_pin(user, user_pin)
    {:error, _} = Authenticator.use_pin(user, user_pin)
  end

  test "Create mobile user with dirty mobile number" do
    {:ok, user, _, _} = Authenticator.create_user_by_mobile("+45 30 12 34 56")
    u = Users.get_by_mobile("4530123456")
    u1 = Users.get_by_mobile("+45  30 12 34 56")
    assert user.id == u.id
    assert user.id == u1.id
  end

  test "Password mismatch" do
    {:error, _, _} =
      Authenticator.create_user(%{
        "username" => "August",
        "password" => "tester",
        "password_confirmation" => "testerikke"
      })
  end

  test "Conditional authentication" do
    {:ok, user, _, _} = Authenticator.create_user_by_username("August", "somepassword")

    {:ok, user} =
      Authenticator.add_perms(user, %{"admin" => [:read, :write], "special" => [:read, :write]})

    {:ok, %Guard.User{username: "august"}} =
      Session.authenticate(%{
        "username" => "August",
        "password" => "somepassword",
        "perm" => "admin"
      })

    {:ok, %Guard.User{username: "august"}} =
      Session.authenticate(%{
        "username" => "August",
        "password" => "somepassword",
        "perm" => "special"
      })

    {:error, :forbidden} =
      Session.authenticate(%{
        "username" => "August",
        "password" => "somepassword",
        "perm" => "notspecial"
      })

    {:ok, %Guard.User{username: "august"}} =
      Session.authenticate(%{
        "username" => "August",
        "password" => "somepassword",
        "all_perms" => ["admin"]
      })

    {:ok, %Guard.User{username: "august"}} =
      Session.authenticate(%{
        "username" => "August",
        "password" => "somepassword",
        "all_perms" => ["special", "admin"]
      })

    {:error, :forbidden} =
      Session.authenticate(%{
        "username" => "August",
        "password" => "somepassword",
        "all_perms" => ["admin", "notspecial", "special"]
      })

    {:ok, %Guard.User{username: "august"}} =
      Session.authenticate(%{
        "username" => "August",
        "password" => "somepassword",
        "any_perms" => ["admin"]
      })

    {:ok, %Guard.User{username: "august"}} =
      Session.authenticate(%{
        "username" => "August",
        "password" => "somepassword",
        "any_perms" => ["testing", "special", "admin", "bonkers"]
      })

    {:error, :forbidden} =
      Session.authenticate(%{
        "username" => "August",
        "password" => "somepassword",
        "any_perms" => ["notspecial", "another"]
      })
  end
end
