# Request                              Response
# MUST include:  * channel             MUST include:  * channel
#                * clientId                           * successful
#                * subscription                       * clientId
#                                                     * subscription
# MAY include:   * ext                 MAY include:   * error
#                * id                                 * advice
#                                                     * ext
#                                                     * id

defmodule Pixie.Unsubscribe do
  alias Pixie.Protocol.Error
  alias Pixie.Backend
  import Pixie.Utils.Map

  def handle(%{message: %{channel: nil}}=event),      do: parameter_missing(event)
  def handle(%{message: %{client_id: nil}}=event),    do: parameter_missing(event)
  def handle(%{message: %{subscription: nil}}=event), do: parameter_missing(event)

  def handle(%{message: %{client_id: c_id}, client: nil, response: r}=event) do
    case Backend.get_client(c_id) do
      nil ->
        %{event | response: Error.client_unknown(r, c_id)}
      client ->
        handle %{event | client: client}
    end
  end

  def handle event do
    unsubscribe Pixie.ExtensionRegistry.handle event
  end

  defp unsubscribe(%{message: %{subscription: channel, client_id: client_id}, response: %{error: nil}}=event) do
    Backend.unsubscribe client_id, channel
    event
  end

  defp unsubscribe(event), do: event

  defp parameter_missing %{message: m, response: r}=event do
    missing = []
      |> missing_key?(m, :channel)
      |> missing_key?(m, :client_id)
      |> missing_key?(m, :subscription)

    %{event | response: Error.parameter_missing(r, missing)}
  end
end
