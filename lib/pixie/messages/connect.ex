# Convert incomming connect messages into a struct.
# We don't do any validation here, as we're just building a data structor for
# the server to handle.


# Request                              Response
# MUST include:  * channel             MUST include:  * channel
#                * clientId                           * successful
#                * connectionType                     * clientId
# MAY include:   * ext                 MAY include:   * error
#                * id                                 * advice
#                                                     * ext
#                                                     * id
#                                                     * timestamp

defmodule Pixie.Message.Connect do
  defstruct channel: nil, client_id: nil, connection_type: nil, ext: nil, id: nil
  import Pixie.Utils.Message

  def init %{}=message do
    %Pixie.Message.Connect{}
      |> get(message, :channel)
      |> get(message, :client_id)
      |> get(message, :connection_type)
      |> get(message, :ext)
      |> get(message, :id)
  end
end
