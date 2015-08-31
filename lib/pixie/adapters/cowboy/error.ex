require Logger

defmodule Pixie.Adapter.Cowboy.Error do

  def not_found req do
    send_error req, 404, "Not Found"
  end

  def method_not_allowed req do
    send_error req, 405, "Method Not Allowed"
  end

  def not_acceptable req do
    send_error req, 406, "Not Acceptable"
  end

  def unprocessable_entity req do
    send_error req, 422, "Unprocessable Entity"
  end

  defp send_error req, status, message do
    send_error req, status, message, default_headers
  end

  defp send_error req, status, message, headers do
    Logger.info "Sending #{status}: #{inspect message}"
    {:ok, req} = :cowboy_req.reply(status, headers, message, req)
    {:ok, req, nil}
  end

  defp default_headers do
    [
      {"content-type", "text/plain"}
    ]
  end
end
