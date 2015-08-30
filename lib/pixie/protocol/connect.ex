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
  alias Pixie.Protocol.Error
  alias Pixie.Backend
  import Pixie.Utils.Map

  def handle(%{message: %{client_id: nil}}=event),       do: parameter_missing(event)
  def handle(%{message: %{channel: nil}}=event),         do: parameter_missing(event)
  def handle(%{message: %{connection_type: nil}}=event), do: parameter_missing(event)

  # Get the client from the backend and call handle again.
  def handle %{message: %{client_id: c_id}, client: nil, response: r}=event do
    case Backend.get_client(c_id) do
      nil ->
        %{event | response: Error.client_unknown(r, c_id)}
      client ->
        handle %{event | client: client}
    end
  end

  # Validate the connection type and respond.
  def handle(%{message: %{connection_type: connection_type}, client: client, response: %{advice: a}=r}=event) when is_pid(client) do
    if Set.member? Pixie.enabled_transports, connection_type do
      transport = Pixie.Client.transport client, connection_type
      advice    = Pixie.Transport.advice transport, a
      Pixie.ExtensionRegistry.handle %{event | response: %{r | advice: advice}}
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
