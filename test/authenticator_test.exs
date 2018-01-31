defmodule Doorman.AuthenticatorTest do
  use Doorman.ModelCase
  alias Doorman.Authenticator

  test "Create missing user" do
    {:error, _, _} = Authenticator.create_user(%{})
  end

  test "Create user" do
    {:ok, _, _} = Authenticator.create_user(%{"username"=>"August"})
    {:error, _, _} = Authenticator.create_user(%{"username"=>"August"})
  end

  test "Create mobile user" do
    {:ok, user, _} = Authenticator.create_user_by_mobile("4530123456")
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
