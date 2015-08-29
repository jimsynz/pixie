# Convert incoming handshake messages into a struct.
# We don't do any validation here, as we're just building a data structure for
# the server to handle.

# Request
# MUST include:  * channel
#                * version
#                * supportedConnectionTypes
# MAY include:   * minimumVersion
#                * ext
#                * id

defmodule Pixie.Message.Handshake do
  defstruct channel: nil, version: nil, supported_connection_types: nil, minimum_version: nil, ext: nil, id: nil

  def init %{}=message do
    %Pixie.Message.Handshake{}
      |> get(message, :channel)
      |> get(message, :version)
      |> get(message, :supported_connection_types)
      |> get(message, :minimum_version)
      |> get(message, :ext)
      |> get(message, :id)
  end

  def get handshake, message, :supported_connection_types=field do
    case Map.get message, field do
      ct when is_list(ct) ->
        Map.put handshake, field, Enum.into(ct, HashSet.new)
      _ ->
        handshake
    end
  end

  def get(h,m,f), do: Pixie.Utils.Message.get(h,m,f)
end
