defmodule Guard.DeviceTest do
  use Guard.ModelCase
  use Plug.Test
  import  Guard.RouterTestHelper
 

  test 'push' do
    device = %{"device"=> %{"token": "magic", "platform": "android"}}
    response = send_json(:post, "/guard/registration/device", device)
    assert response.status == 201

    response = send_json(:delete, "/guard/registration/device/android/magic")
    assert response.status == 200

    response = send_json(:delete, "/guard/registration/device/android/magic")
    assert response.status == 404

    response = send_json(:delete, "/guard/registration/device/android/moremagic")
    assert response.status == 404
  end
end 
