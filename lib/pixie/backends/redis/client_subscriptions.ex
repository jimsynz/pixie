defmodule Pixie.Backend.Redis.ClientSubscriptions do
  import Pixie.Backend.Redis.Connection

  @moduledoc false

  def get client_id do
    {:ok, subs} = query ["SMEMBERS", key(client_id)]
    subs
  end

  def subscribed? client_id, channel_name do
    case query ["SISMEMBER", key(client_id), channel_name] do
      {:ok, "1"} -> true
      {:ok, "0"} -> false
    end
  end

  def subscribe client_id, channel_name do
    {ok, _} = query ["SADD", key(client_id), channel_name]
    ok
  end

  def unsubscribe client_id, channel_name do
    {ok, _} = query ["SREM", key(client_id), channel_name]
    ok
  end

  defp key client_id do
    cluster_namespace("client_subscriptions:#{client_id}")
  end
end
