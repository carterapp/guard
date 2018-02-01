defmodule Doorman.Pusher do


  def send_user_message(user, message, callback \\ nil) do
    Doorman.Pusher.Server.send_user_message(Doorman.Pusher.Server, user, message, callback)
  end

  def status() do
    Doorman.Pusher.Server.status(Doorman.Pusher.Server)
  end

  def send_user_notification(user, title, body, callback \\ nil) do
    send_user_message(user, %{notification: %{body: body, title: title}}, callback)
  end

  def send_message(message, callback \\ nil) do
    Doorman.Pusher.Server.send_message(Doorman.Pusher.Server, message, callback)
  end

end
