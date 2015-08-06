defmodule Pixie.CowboyHandler do
  alias Pixie.Errors
  alias Pixie.Bayeux

  @behaviour :cowboy_http_handler

  def init _transport, req, opts do
    init req, opts
  end

  def init req, _opts do
    {method, _req} = :cowboy_req.method(req)
    process req, method
  end

  def terminate _reason, _req, _state do
    :ok
  end

  defp process req, "POST" do
    process_post req, is_json_request?(req)
  end

  defp process req, "GET" do
    process_get req, is_upgrade_request?(req)
  end

  defp process req, _ do
    Errors.method_not_allowed req
  end

  defp process_post req, _is_json_request=true do
    {:ok, body, _req} = :cowboy_req.body req
    if byte_size(body) > 0 do
      Bayeux.process req, Poison.decode(body)
    else
      Errors.not_acceptable req
    end
  end

  defp process_post req, _is_json_request=false do
    {:ok, queries, _req} = :cowboy_req.body_qs req
    Bayeux.process req, keyword_list_to_map(queries)
  end

  defp process_get req, _is_upgrade_request=true do
    {:upgrade, :protocol, Pixie.WebsocketHandler}
  end

  defp process_get req, _is_upgrade_request=false do
    {qs, _req} = :cowboy_req.qs(req)
    if byte_size(qs) > 0 do
      {:ok, queries} = :cowboy_req.parse_qs req
      Bayeux.process req, keyword_list_to_map(queries)
    else
      Errors.not_found req
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
    upgrade_hdr = String.downcase upgrade_hdr
    case upgrade_hdr do
      "websocket" -> true
      _           -> false
    end
  end

  defp keyword_list_to_map kw_list do
    Enum.reduce kw_list, %{}, fn({key,value}, map)->
      Dict.put map, key, value
    end
  end
end
