# Request                              Response
# MUST include:  * channel             MUST include:  * channel
#                * clientId                           * successful
#                * subscription                       * clientId
#                                                     * subscription
# MAY include:   * ext                 MAY include:   * error
#                * id                                 * advice
#                                                     * ext
#                                                     * id

defmodule Pixie.Response.Subscribe do
  defstruct channel: "/meta/subscribe", client_id: nil, error: nil, advice: nil, ext: nil, id: nil
  import Pixie.Utils.Response

  def init %Pixie.Message.Subscribe{}=message do
    %Pixie.Response.Subscribe{}
      |> put(message, :id)
      |> put(message, :client_id)
      |> put(message, :subscription)
  end
end
