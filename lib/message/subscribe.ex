# Request                              Response
# MUST include:  * channel             MUST include:  * channel
#                * clientId                           * successful
#                * subscription                       * clientId
#                                                     * subscription
# MAY include:   * ext                 MAY include:   * error
#                * id                                 * advice
#                                                     * ext
#                                                     * id

defmodule Pixie.Message.Subscribe do
  defstruct channel: nil, client_id: nil, subscription: nil, ext: nil, id: nil
  import Pixie.Utils.Message

  def init %{}=message do
    %Pixie.Message.Subscribe{}
      |> get(message, :channel)
      |> get(message, :client_id)
      |> get(message, :subscription)
      |> get(message, :ext)
      |> get(message, :id)
  end
end
