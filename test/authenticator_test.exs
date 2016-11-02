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

  test "Password mismatch" do
    {:error, _, _} = Authenticator.create_user(%{"username"=>"August", "password"=>"tester", "password_confirmation"=>"testerikke"})
  end


end
