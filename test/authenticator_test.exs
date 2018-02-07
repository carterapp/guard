defmodule Doorman.AuthenticatorTest do
  use Doorman.ModelCase
  alias Doorman.Authenticator

  test "Create missing user" do
    {:error, _, _} = Authenticator.create_user(%{})
  end

  test "Create user" do
    {:ok, _, _, _} = Authenticator.create_user(%{"username"=>"August"})
    {:error, _, _} = Authenticator.create_user(%{"username"=>"August"})
  end

  test "Test transactional creation" do
    extra_fn = fn(user) -> 
      assert !is_nil(user.id)
      _ = Authenticator.get_by_id!(user.id)
      {:ok, user, _jwt, _response} = Authenticator.create_user(%{"username"=>"AugustAndre"})
      {:ok, user}
    end
    {:ok, user1, _, _} = Authenticator.create_user(%{"username"=>"August"}, extra_fn)
    assert !is_nil(Authenticator.get_by_username!("August"))
    assert !is_nil(Authenticator.get_by_username!("AugustAndre"))

    extra_fn2 = fn(user) -> 
      {:ok, user, _jwt, _resp} = Authenticator.create_user_by_mobile("555-121")
      assert !is_nil(Authenticator.get_by_username("555-512"))
      {:error, :im_a_teapot}
    end
    {:error, _, _} = Authenticator.create_user_by_username("Emilia", "badpassword", extra_fn2)
    assert is_nil(Authenticator.get_by_username("Emilia"))
    assert is_nil(Authenticator.get_by_username("555-512"))
  end

  test "Create mobile user" do
    {:ok, user, _, _} = Authenticator.create_user_by_mobile("4530123456")
    {:error, _, _} = Authenticator.create_user_by_mobile("4530123456")
    {:ok, user} = Authenticator.generate_pin(user)
    pin = user.pin
    {:error, _} = Authenticator.confirm_mobile_pin(user, "wrong")
    {:ok, user} = Authenticator.confirm_mobile_pin(user, pin)
    {:error, _} = Authenticator.confirm_mobile_pin(user, nil)
    {:error, _} = Authenticator.confirm_mobile_pin(user, pin)
  end

  test "Password mismatch" do
    {:error, _, _} = Authenticator.create_user(%{"username"=>"August", "password"=>"tester", "password_confirmation"=>"testerikke"})
  end


end
