# Request                              Response
# MUST include:  * channel             MUST include:  * channel
#                * data                               * successful
# MAY include:   * clientId            MAY include:   * id
#                * id                                 * error
#                * ext                                * ext

defmodule Pixie.Message.Publish do
  defstruct channel: nil, data: nil, client_id: nil, id: nil, ext: nil
  import Pixie.Utils.Message

  def init %{}=message do
    %Pixie.Message.Publish{}
      |> get(message, :channel)
      |> get(message, :data)
      |> get(message, :client_id)
      |> get(message, :id, Pixie.Utils.RandomId.generate)
      |> get(message, :ext)
  end
end
