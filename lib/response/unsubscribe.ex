# Request                              Response
# MUST include:  * channel             MUST include:  * channel
#                * clientId                           * successful
#                * subscription                       * clientId
#                                                     * subscription
# MAY include:   * ext                 MAY include:   * error
#                * id                                 * advice
#                                                     * ext
#                                                     * id

defmodule Pixie.Response.Unsubscribe do
  defstruct channel: "/meta/unsubscribe", client_id: nil, error: nil, advice: nil, ext: nil, id: nil
  import Pixie.Utils.Response

  def init %Pixie.Message.Unsubscribe{}=message do
    %Pixie.Response.Unsubscribe{}
      |> put(message, :id)
      |> put(message, :client_id)
      |> put(message, :subscription)
  end
end
