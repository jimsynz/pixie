defmodule Pixie.Backend.Redis.Namespaces do
  import Pixie.Backend.Redis.Connection
  use GenServer

  def generate_namespace length do
    id   = Pixie.Utils.RandomId.generate length

    case query ["SISMEMBER", key, id] do
      {:ok, "1"} ->
        generate_namespace length

      {:ok, "0"} ->
        {:ok, _} = query ["SADD", key, id]
        id

      error ->
        error
    end
  end

  def release_namespace namespace do
    {:ok, _} = query ["SREM", key, namespace]
  end

  defp key, do: cluster_namespace("namespaces")
end
