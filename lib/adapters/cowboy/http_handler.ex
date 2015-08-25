require Logger

defmodule Pixie.Adapter.CowboyHttp do
  alias Pixie.Adapter.CowboyError, as: Error
  alias Pixie.Bayeux

  @behaviour :cowboy_http_handler

  def init _transport, req, opts do
    init req, opts
  end

  def init req, _opts do
    verify req, is_upgrade_request?(req)
  end

  def handle req, _state do
    {method, req} = :cowboy_req.method(req)
    Logger.debug "handing request:  #{inspect req}"
    response = process req, method
    Logger.debug "sending response: #{inspect response}"
    response
  end

  def terminate _reason, _req, _state do
    :ok
  end

  defp verify _req, _is_upgrade_request=true do
    {:upgrade, :protocol, Pixie.Adapter.CowboyWebsocket}
  end

  defp verify req, _is_upgrade_request do
    {:ok, req, nil}
  end

  defp process req, "POST" do
    process_post req, is_json_request?(req)
  end

  defp process req, "GET" do
    process_get req
  end

  defp process req, _ do
    Error.method_not_allowed req
  end

  defp process_post req, _is_json_request=true do
    {:ok, body, req} = :cowboy_req.body req
    case byte_size(body) do
      0 -> Error.not_acceptable req
      _ -> Bayeux.process req, Poison.decode!(body)
    end
  end

  defp process_post req, _is_json_request=false do
    {:ok, queries, req} = :cowboy_req.body_qs req
    Bayeux.process req, keyword_list_to_map(queries)
  end

  defp process_get req do
    {qs, req} = :cowboy_req.qs(req)
    case byte_size(qs) do
      0 ->
        Error.not_found req
      _ ->
        {queries, req} = :cowboy_req.qs_vals req
        Bayeux.process req, keyword_list_to_map(queries)
    end
  end

  defp is_json_request? req do
    {content_type, _req} = :cowboy_req.header("content-type", req)
    case content_type do
      "application/json" -> true
      _                  -> false
    end
  end

  defp is_upgrade_request? req do
    {upgrade_hdr, _req} = :cowboy_req.header("upgrade", req)
    case upgrade_hdr do
      "websocket" -> true
      "WebSocket" -> true
      _           -> false
    end
  end

  defp keyword_list_to_map kw_list do
    Enum.reduce kw_list, %{}, fn({key,value}, map)->
      Dict.put map, key, value
    end
  end
end
