# MUST contain  * clientId
# MAY contain   * ext
#               * id
defmodule Pixie.Message.Disconnect do
  defstruct channel: nil, client_id: nil, ext: nil, id: nil
  import Pixie.Utils.Message

  def init %{}=message do
    %Pixie.Message.Disconnect{}
      |> get(message, :channel)
      |> get(message, :client_id)
      |> get(message, :ext)
      |> get(message, :id)
  end
end
