defmodule Pixie.Backend.Redis.Channels do
  require Logger
  import Pixie.Utils.Backend
  import Pixie.Backend.Redis.Connection

  def create channel_name do
    term = channel_name |> compile_channel_matcher |> :erlang.term_to_binary
    {:ok, _} = query ["HSET", key, channel_name, term]
    Logger.info "[#{channel_name}]: Channel created."
    :ok
  end

  def destroy channel_name do
    {:ok, _} = query ["HDEL", key, channel_name]
    Logger.info "[#{channel_name}]: Channel destroyed."
    :ok
  end

  def exists? channel_name do
    case query ["HEXISTS", key, channel_name] do
      {:ok, "1"} -> true
      _          -> false
    end
  end

  def get channel_name do
    compile_channel_matcher channel_name
  end

  def list do
    {:ok, channels} = query ["HGETALL", key]
    channels |> Enum.chunk(2) |> Enum.map fn
      [key,val]-> {key, :erlang.binary_to_term val}
    end
  end

  defp key do
    cluster_namespace("channels")
  end
end
