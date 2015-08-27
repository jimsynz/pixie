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
  alias Pixie.Protocol.Error
  alias Pixie.Backend
  import Pixie.Utils.Map

  def handle %{message: %{client_id: nil}}=event do
    parameter_missing event
  end

  def handle %{message: %{channel: nil}}=event do
    parameter_missing event
  end

  def handle %{message: %{connection_type: nil}}=event do
    parameter_missing event
  end

  # Get the client from the backend and call handle again.
  def handle %Event{message: %{client_id: c_id}, client: nil, response: r}=event do
    case Backend.get_client(c_id) do
      nil ->
        %{event | response: Error.client_unknown(r, c_id)}
      %Pixie.Client{}=client->
        handle %{event | client: client}
    end
  end

  # Validate the connection type and respond.
  def handle(%Event{message: %{connection_type: connection_type}=m, client: %Pixie.Client{}, response: %{advice: a}=r}=event) do
    if Set.member? Pixie.Bayeux.transports, connection_type do
      if connection_type == "eventsource" do
        %{event | response: %{m | advice: %{a | timeout: 0}}}
      else
        event
      end
    else
      %{event | response: Error.conntype_mismatch(r, [connection_type])}
    end
  end

  # Return a parameter_missing error with a list of missing params.
  defp parameter_missing %{message: m, response: r}=event do
    missing = []
      |> missing_key?(m, :channel)
      |> missing_key?(m, :client_id)
      |> missing_key?(m, :connection_type)

    %{event | response: Error.parameter_missing(r, missing)}
  end
end
