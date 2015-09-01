defmodule Pixie.Adapter.Plug do
  use Plug.Builder
  import Pixie.Adapter.HttpError
  require Logger

  @valid_jsonp_callback ~r|^[a-z_\$][a-z0-9_\$]*(\.[a-z_\$][a-z0-9_\$]*)*$|i

  if Mix.env == :dev do
    use Plug.Debugger
  end
  plug Plug.Logger
  plug Plug.Parsers,
    parsers:      [:urlencoded, :json, :multipart],
    pass:         ["text/*", "application/json"],
    json_decoder: Poison

  plug :handle

  def handle %{method: "OPTIONS"}=conn, _ do
    halt handle_options conn
  end

  def handle conn, _ do
    if get_req_header(conn, "access-control-request-method") == ["POST"] do
      halt handle_options conn
    else
      halt handle_request fetch_query_params(conn)
    end
  end

  defp handle_request(%{method: "POST", params: %{"_json" => json}}=conn) when is_list(json) do
    data = Pixie.Protocol.handle json
    conn = put_resp_content_type conn, "application/json"
    send_resp conn, 200, Poison.encode! data
  end

  defp handle_request %{method: "POST", params: %{"message" => json}}=conn do
    data = Pixie.Protocol.handle json
    conn = put_resp_content_type conn, "application/json"
    send_resp conn, 200, Poison.encode! data
  end

  defp handle_request(%{method: "POST"}=conn) do
    bad_request conn
  end

  defp handle_request %{method: "GET", query_params: %{"message" => json}=params}=conn do
    jsonp = Map.get params, "jsonp", "jsonpcallback"

    if Regex.match? @valid_jsonp_callback, jsonp do
      json  = Poison.decode! json
      conn = case get_req_header(conn, "origin") do
        [value] -> put_resp_header conn, "access-control-allow-origin", value
        [] -> conn
      end
      data = Pixie.Protocol.handle json
      data = Poison.encode! data

      data = "/**/#{jsonp}(#{data});"

      conn = merge_resp_headers conn, %{
        "cache-control"          => "no-cache, no-store",
        "x-content-type-options" => "nosniff",
        "content-disposition"    => "attachment; filename=f.txt",
        "content-length"         => data |> String.length |> Integer.to_string,
        "connection"             => "close"
      }

      conn = put_resp_content_type conn, "text/javascript"

      send_resp conn, 200, data
    else
      Logger.error "Invalid JSONP callback: #{inspect jsonp}"
      bad_request conn
    end
  end

  defp handle_request conn do
    Logger.debug "Unhandled connection: #{inspect conn}"
    not_found conn
  end

  defp handle_options conn do
    conn = merge_resp_headers conn, %{
      "access-control-allow-credentials" => "false",
      "access-control-allow-headers"     => "Accept, Authorization, Content-Type, Pragma, X-Requested-With",
      "access-control-allow-methods"     => "POST, GET",
      "access-control-allow-origin"      => "*",
      "access-control-max-age"           => "86400"
    }
    send_resp conn, 200, ""
  end

end
