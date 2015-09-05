defmodule Pixie.DebugExtension do
  use Pixie.Extension
  require Logger

  def incoming event do
    Logger.debug "#{inspect __MODULE__}.incoming: #{inspect event}"
    event
  end

  def outgoing message do
    Logger.debug "#{inspect __MODULE__}.outgoing: #{inspect message}"
    message
  end
end
