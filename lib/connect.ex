# Request                              Response
# MUST include:  * channel             MUST include:  * channel
#                * clientId                           * successful
#                * connectionType                     * clientId
# MAY include:   * ext                 MAY include:   * error
#                * id                                 * advice
#                                                     * ext
#                                                     * id
#                                                     * timestamp

defmodule Pixie.Connect do
  alias Pixie.Event
  alias Pixie.Bayeux.Error
  alias Pixie.Backend
  import Pixie.Utils

  def handle(%Event{message: %{client_id: c_id}=m, client: c, response: r}=event) when is_nil(c) and not is_nil(c_id) do
    case Pixie.Backend.get_client(c_id) do
      nil ->
        %{event | response: Error.client_unknown(r, c_id)}
      %Pixie.Client{}=client->
        handle %{event | client: client}
    end
  end

  def handle %Event{message: m, response: r}=event do
    missing = []
      |> missing_key?(m, :channel)
      |> missing_key?(m, :client_id)
      |> missing_key?(m, :connection_type)

    %{event | response: Error.parameter_missing(r, missing)}
  end
end
