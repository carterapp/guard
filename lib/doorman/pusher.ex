defmodule Doorman.Pusher do


  def send_user_message(user, message) do
    Doorman.Pusher.Server.send_user_message(Doorman.Pusher.Server, user, message)
  end

  def send_message(message) do
    Doorman.Pusher.Server.send_message(Doorman.Pusher.Server, message)
  end

end
