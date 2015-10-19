defmodule Pixie.DebugExtension do
  use Pixie.Extension
  require Logger

  @moduledoc """
  Use this extension for debugging only - it logs every event to `Logger`
  which has the unfortunate side effect of exploding your VM when there's
  logs of traffic.
  """

  def incoming event do
    Logger.debug "#{inspect __MODULE__}.incoming: #{inspect event}"
    event
  end

  def outgoing message do
    Logger.debug "#{inspect __MODULE__}.outgoing: #{inspect message}"
    message
  end
end
