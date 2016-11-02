defmodule Doorman.DeviceTest do
  use Doorman.ModelCase
  use Plug.Test
  import  Doorman.RouterTestHelper
 

  test 'push' do
    device = %{"device"=> %{"token": "magic", "platform": "android"}}
    response = send_json(:post, "/doorman/registration/device", device)
    assert response.status == 201

    response = send_json(:delete, "/doorman/registration/device", device)
    assert response.status == 200

    response = send_json(:delete, "/doorman/registration/device", device)
    assert response.status == 404

    device2 = %{"device"=> %{"token": "moremagic", "platform": "android"}}
    response = send_json(:delete, "/doorman/registration/device", device2)
    assert response.status == 404
  end
end 
