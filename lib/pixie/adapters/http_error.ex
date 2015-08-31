defmodule Pixie.Adapter.HttpError do
  import Plug.Conn

  def bad_request conn do
    error conn, 400, "Bad request"
  end

  def not_found conn do
    error conn, 404, "Not found"
  end

  def error conn, status, message do
    conn = put_resp_content_type conn, "text/plain"
    send_resp conn, status, message
  end
end
