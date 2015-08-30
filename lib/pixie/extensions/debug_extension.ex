defmodule Pixie.DebugExtension do
  use Pixie.Extension
  require Logger

  def handle event do
    Logger.debug "#{inspect __MODULE__}: #{inspect event}"
    event
  end
end
