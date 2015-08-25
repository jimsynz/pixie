# Create a struct to handle outgoing handshake responses.
# We don't do any validation here, as we're just building a data structure for
# the server to handle.

# Success Response                             Failed Response
# MUST include:  * channel                     MUST include:  * channel
#                * version                                    * successful
#                * supportedConnectionTypes                   * error
#                * clientId                    MAY include:   * supportedConnectionTypes
#                * successful                                 * advice
# MAY include:   * minimumVersion                             * version
#                * advice                                     * minimumVersion
#                * ext                                        * ext
#                * id                                         * id
#                * authSuccessful

defmodule Pixie.Response.Handshake do
  @version "1.0"

  # Note that we don't have a `successful` field here. We'll calculate it
  # when we encode to JSON.
  defstruct channel: "/meta/handshake", version: @version, supported_connection_types: HashSet.new, client_id: nil, error: nil, minimum_version: nil, advice: nil, ext: nil, id: nil, auth_successful: nil

  def init %Pixie.Message.Handshake{}=message do
    %Pixie.Response.Handshake{}
      |> put(message, :id)
      |> put(message, :client_id)
  end

  defp put handshake, message, field do
    case Map.get message, field do
      nil -> handshake
      v   -> Map.put handshake, field, v
    end
  end
end
