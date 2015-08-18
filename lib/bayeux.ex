require Logger

defmodule Pixie.Bayeux do
  alias Pixie.Errors

  def process req, [] do
    {:ok, req, nil}
  end

  def process(req, list) when is_list(list) and length(list) == 1 do
    data = List.first list
    process req, data
  end

  def process(req, list) when is_list(list) do
    Enum.map list, fn(data)-> process req, data end
  end

  def process req, %{"channel" => "/meta/handshake"}=message do
    id         = :erlfaye_api.generate_id
    message_id = Map.get message, :messageId, nil
    cache_pid  = spawn :erlfaye_api, :cache_loop, [[], 0]

    :erlfaye_api.replace_connection(id, 0, cache_pid, :handshake)

    response = %{
      channel:                  "/meta/handshake",
      version:                  "1.0",
      supportedConnectionTypes: ["websocket", "long-polling", "callback-polling"],
      clientId:                 id,
      successful:               true,
      advice: %{
        reconnect: "retry",
        interval:  2000
      }
    }

    response = case message_id do
      nil -> response
      id  -> Map.put response, :id, id
    end

    Logger.debug "Message:  #{inspect message}"
    Logger.debug "Response: #{inspect response}"

    send_json req, response
  end

  def process req, message do
    Logger.debug "Unhandled Bayeux message: #{inspect(message)}"
    Errors.not_acceptable req
  end

  defp send_json req, json do
    {:ok, req} = :cowboy_req.reply 200, default_headers, Poison.encode!(json), req
    {:ok, req, nil}
  end

  defp default_headers do
    [
      {"content-type", "application/json"}
    ]
  end
end
