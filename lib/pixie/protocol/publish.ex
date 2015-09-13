# Request                              Response
# MUST include:  * channel             MUST include:  * channel
#                * data                               * successful
# MAY include:   * clientId            MAY include:   * id
#                * id                                 * error
#                * ext                                * ext


# As per [1] it is optional for a server to handle publishes from unconnected or
# unsubscribed clients.  I've opted to enforce that only subscribed clients can
# publish to a channel.  I'm open to changing this if you have a good argument
# I'm happy to hear it.  Send a PR.
#
# 1: http://svn.cometd.org/trunk/bayeux/bayeux.html#toc_63

defmodule Pixie.Publish do
  alias Pixie.Protocol.Error
  alias Pixie.Backend
  import Pixie.Utils.Map

  def handle(%{message: %{channel: nil}}=event), do: parameter_missing(event)
  def handle(%{message: %{data: nil}}=event),    do: parameter_missing(event)

  def handle %{message: %{client_id: nil}, client_id: nil, response: r}=event do
    %{event | response: Error.parameter_missing(r, [:client_id])}
  end

  # Get the client from the backend and call handle again.
  def handle %{message: %{client_id: c_id}, client_id: nil, response: r}=event do
    case Backend.get_client(c_id) do
      nil ->
        %{event | response: Error.client_unknown(r, c_id)}
      _client ->
        handle %{event | client_id: c_id}
    end
  end

  def handle(%{client_id: client_id, response: r}=event) do
    %{message: %{channel: channel_name}}=event = Pixie.ExtensionRegistry.incoming event
    if Pixie.Backend.client_subscribed? client_id, channel_name do
      publish event
    else
      %{event | response: Error.publish_failed(r, channel_name)}
    end
  end

  defp publish(%{message: nil}=event), do: event

  defp publish %{message: message, response: %{error: nil}}=event do
    Pixie.Backend.publish message
    event
  end

  defp publish(event), do: event

  # Return a parameter_missing error with a list of missing params.
  defp parameter_missing %{message: m, response: r}=event do
    missing = []
      |> missing_key?(m, :channel)
      |> missing_key?(m, :data)

    %{event | response: Error.parameter_missing(r, missing)}
  end
end
