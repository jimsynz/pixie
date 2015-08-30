# Request                              Response
# MUST include:  * channel             MUST include:  * channel
#                * clientId                           * successful
#                * subscription                       * clientId
#                                                     * subscription
# MAY include:   * ext                 MAY include:   * error
#                * id                                 * advice
#                                                     * ext
#                                                     * id

defmodule Pixie.Subscribe do
  alias Pixie.Protocol.Error
  alias Pixie.Backend
  import Pixie.Utils.Map

  def handle(%{message: %{channel: nil}}=event),      do: parameter_missing(event)
  def handle(%{message: %{client_id: nil}}=event),    do: parameter_missing(event)
  def handle(%{message: %{subscription: nil}}=event), do: parameter_missing(event)

  def handle(%{message: %{subscription: ("/meta/" <> _)=channel}, response: r}=event) do
    %{event | response: Error.channel_forbidden(r, channel)}
  end

  def handle(%{message: %{client_id: c_id}, client: nil, response: r}=event) do
    case Backend.get_client(c_id) do
      nil ->
        %{event | response: Error.client_unknown(r, c_id)}
      client ->
        handle %{event | client: client}
    end
  end

  def handle(event) do
    subscribe Pixie.ExtensionRegistry.handle event
  end

  defp subscribe %{message: %{subscription: channel, client_id: client_id}, response: %{error: nil}}=event do
    Backend.subscribe client_id, channel
    event
  end

  defp subscribe event do
    event
  end

  defp parameter_missing %{message: m, response: r}=event do
    missing = []
      |> missing_key?(m, :channel)
      |> missing_key?(m, :client_id)
      |> missing_key?(m, :subscription)

    %{event | response: Error.parameter_missing(r, missing)}
  end
end
