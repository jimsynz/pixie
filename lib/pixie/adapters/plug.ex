defmodule Pixie.Adapter.Plug do
  use Plug.Builder
  require Logger

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
    handle_options conn
  end

  def handle conn, _ do
    if get_req_header(conn, "access-control-request-method") == ["POST"] do
      handle_options conn
    else
      handle_request fetch_query_params(conn)
    end
  end

  defp handle_request %{method: "POST", params: %{"_json" => json}}=conn do
    Logger.debug "Received JSON: #{inspect json}"
    data = Pixie.Protocol.handle json
    conn = put_resp_header conn, "content-type", "application/json"
    send_resp conn, 200, Poison.encode! data
  end

  defp handle_request conn do
    Logger.debug "Unhandled connection: #{inspect conn}"
    send_resp conn, 404, "Not found"
  end

  defp handle_options conn do
    conn = merge_resp_headers conn, %{
      "Access-Control-Allow-Credentials" => "false",
      "Access-Control-Allow-Headers"     => "Accept, Authorization, Content-Type, Pragma, X-Requested-With",
      "Access-Control-Allow-Methods"     => "POST, GET",
      "Access-Control-Allow-Origin"      => "*",
      "Access-Control-Max-Age"           => "86400"
    }
    send_resp conn, 200, ""
  end
end
