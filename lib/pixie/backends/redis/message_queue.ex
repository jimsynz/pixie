defmodule Pixie.Backend.Redis.MessageQueue do
  import Pixie.Backend.Redis.Connection

  def queue client_id, messages do
    messages = Enum.map(messages, &:erlang.term_to_binary/1)
    {ok, _}  = query ["LPUSH", key(client_id)] ++  messages
    Pixie.Backend.Redis.Notifications.trigger client_id
    ok
  end

  def dequeue client_id do
    collect_messages_for client_id
  end

  def destroy client_id do
    {ok, _} = query ["DELETE", key(client_id)]
    ok
  end

  defp key client_id do
    cluster_namespace("message_queue:#{client_id}")
  end

  defp collect_messages_for client_id do
    collect_messages_for client_id, lpop(client_id), []
  end

  defp collect_messages_for _client_id, nil, acc do
    acc
  end

  defp collect_messages_for client_id, value, acc do
    collect_messages_for client_id, lpop(client_id), [value | acc]
  end

  defp lpop client_id do
    case query ["LPOP", key(client_id)] do
      {:ok, value} when is_binary(value) ->
        :erlang.binary_to_term value
      _ -> nil
    end
  end
end
