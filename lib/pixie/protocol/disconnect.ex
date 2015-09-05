defmodule Pixie.Disconnect do
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

  def handle %{message: %{client_id: c_id}, client: nil, response: r}=event do
    case Backend.get_client(c_id) do
      nil ->
        %{event | response: Error.client_unknown(r, c_id)}
      client ->
        handle %{event | client: client}
    end
  end

  def handle event do
    destroy_client Pixie.ExtensionRegistry.incoming event
  end

  defp destroy_client %{message: %{client_id: c_id}, response: %{error: nil}}=event do
    Task.async Backend, :destroy_client, [c_id, "Client sent disconnect request."]
    event
  end

  defp destroy_client event do
    event
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
