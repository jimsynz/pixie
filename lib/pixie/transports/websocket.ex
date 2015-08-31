defmodule Pixie.Transport.Websocket do
  use Pixie.Transport.Stream

  def websocket_terminate _reason, _req, _state do
    :ok
  end
end
