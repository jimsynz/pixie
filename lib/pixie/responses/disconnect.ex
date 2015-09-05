defmodule Pixie.Response.Disconnect do
  defstruct channel: "/meta/disconnect", client_id: nil, error: nil, ext: nil, id: nil
  import Pixie.Utils.Response

  @moduledoc """
  Convert an incoming `Pixie.Message.Disconnect` into a response.

      Response
      MUST include:  * channel
                     * successful
                     * clientId
      MAY include:   * error
                     * ext
                     * id

  This struct contains the following keys:

    - `:channel` always `"/meta/disconnect"`.
    - `:client_id` the client ID generated by the server during handshake.
    - `:error` an error message to send to the client explaining why the
      request cannot proceed. Optional.
    - `:ext` an arbitrary map of data the server sends for use in extensions
      (usually authentication information, etc). Optional.
    - `:id` a message ID generated by the client. Optional.
  """

  @doc """
  Create a `Pixie.Response.Disconnect` struct based on some fields from the
  incoming message.
  """
  def init %Pixie.Message.Disconnect{}=message do
    %Pixie.Response.Disconnect{}
      |> put(message, :id)
      |> put(message, :client_id)
  end
end
