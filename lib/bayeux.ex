defmodule Pixie.Bayeux do
  @version "1.0"
  @transports Enum.into(~w| long-polling cross-origin-long-polling callback-polling websocket eventsource |, HashSet.new)

  def version(), do: @version
  def transports(), do: @transports
end
