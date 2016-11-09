defmodule Doorman.Router do

  defmacro __using__(_opts) do
    quote do
      import Doorman.Plug
    end
  end

end
