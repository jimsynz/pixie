defmodule Pixie.Protocol.Error do
  alias Pixie.Utils.String, as: StringUtils

  @errors %{
    version_mismatch:  {300, "Version mismatch"},
    conntype_mismatch: {301, "Connection types not supported"},
    ext_mismatch:      {302, "Extension mismatch"},
    bad_request:       {400, "Bad request"},
    client_unknown:    {401, "Unknown client"},
    parameter_missing: {402, "Missing required parameter"},
    channel_forbidden: {403, "Forbidden channel"},
    channel_invalid:   {405, "Invalid channel"},
    ext_unknown:       {406, "Unknown extension"},
    publish_failed:    {407, "Publish failed"},
    server_error:      {500, "Internal server error"}
  }

  def version_mismatch r, version do
    error r, :version_mismatch, [version]
  end

  def conntype_mismatch r, connection_types do
    error r, :conntype_mismatch, connection_types
  end

  def parameter_missing(r,p) when is_atom(p), do: parameter_missing(r, [p])
  def parameter_missing(r, parameters) when is_list(parameters) do
    parameters = Enum.map(parameters, &StringUtils.camelize/1) |> Enum.sort
    error r, :parameter_missing, parameters
  end

  def client_unknown(r, client_id) do
    error r, :client_unknown, [client_id]
  end

  def channel_forbidden(r, channel) do
    error r, :channel_forbidden, [channel]
  end

  def publish_failed(r, channel) do
    error r, :publish_failed, [channel]
  end

  defp error r, name, args do
    {code, message} = Map.fetch! @errors, name
    Map.put r, :error, "#{code}:#{Enum.join(args, ",")}:#{message}"
  end
end
