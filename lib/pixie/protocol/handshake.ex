defmodule Pixie.Handshake do
  alias Pixie.Event
  alias Pixie.Protocol.Error
  alias Pixie.Backend
  import Pixie.Utils.Map

  # FIXME: I need a way to check this against Pixie.bayeux_version instead of
  #        hard coding it here.
  def handle(%Event{message: %{supported_connection_types: %{__struct__: HashSet}=client_transports, channel: "/meta/handshake", version: "1.0"}, response: response}=event) do
    server_transports = Pixie.enabled_transports
    common_transports = Set.intersection client_transports, server_transports

    if Enum.empty? common_transports do
      %{event | response: Error.conntype_mismatch(response, client_transports)}
    else
      event = %{event | response: %{response | supported_connection_types: common_transports}}
      create_client Pixie.ExtensionRegistry.incoming event
    end
  end

  def handle(%Event{message: %{version: v}, response: r}=event) when not is_nil(v) do
    %{event | response: Error.version_mismatch(r, v) }
  end

  def handle(%Event{message: m, response: r}=event) do
    missing = []
      |> missing_key?(m, :channel)
      |> missing_key?(m, :version)
      |> missing_key?(m, :supported_connection_types)

    %{event | response: Error.parameter_missing(r, missing)}
  end

  defp create_client %{response: %{error: nil}=response}=event do
    {client_id, client} = Backend.create_client
    %{event | client: client, response: %{response | client_id: client_id}}
  end

  defp create_client event do
    event
  end

end
