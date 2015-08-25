defmodule Pixie.Bayeux do
  alias Pixie.Bayeux.Error

  @version "1.0"
  @transports Enum.into(~w| long-polling cross-origin-long-polling callback-polling websocket eventsource |, HashSet.new)

  def version(), do: @version
  def transports(), do: @transports
end
