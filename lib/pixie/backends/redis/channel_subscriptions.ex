defmodule Pixie.Backend.Redis.ChannelSubscriptions do
  import Pixie.Backend.Redis.Connection

  def get channel_name do
    {:ok, client_ids} = query ["SMEMBERS", key(channel_name)]
    client_ids
  end

  def subscriber_count channel_name do
    {:ok, size} = query ["SCARD", key(channel_name)]
    String.to_integer size
  end

  def subscribe channel_name, client_id do
    {ok, _} = query ["SADD", key(channel_name), client_id]
    ok
  end

  def unsubscribe channel_name, client_id do
    {ok, _} = query ["SREM", key(channel_name), client_id]
    ok
  end

  defp key channel_name do
    cluster_namespace("channel_subscriptions:#{channel_name}")
  end
end
