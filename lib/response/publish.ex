# Request                              Response
# MUST include:  * channel             MUST include:  * channel
#                * data                               * successful
# MAY include:   * clientId            MAY include:   * id
#                * id                                 * error
#                * ext                                * ext

defmodule Pixie.Response.Publish do
  defstruct channel: nil, client_id: nil, error: nil, advice: nil, ext: nil, id: nil
  import Pixie.Utils.Response

  def init %Pixie.Message.Publish{}=message do
    %Pixie.Response.Publish{}
      |> put(message, :channel)
      |> put(message, :id)
  end
end
