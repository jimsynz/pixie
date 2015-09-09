defmodule Pixie.Backend.Redis.Clients do
  require Logger
  import Pixie.Backend.Redis.Connection

  alias Timex.Time

  @moduledoc """
  This process manages the generation and removal of client processes.
  """

  def create do
    client_id = Pixie.Backend.generate_namespace
    {:ok, pid} = Pixie.ClientSupervisor.start_child client_id
    {:ok, _} = query ["ZADD", key, now, client_id]
    {client_id, pid}
  end

  def destroy client_id do
    Pixie.ClientSupervisor.terminate_child client_id
    {:ok, _} = query ["ZREM", key, client_id]
  end

  def get client_id do
    if is_valid_client? client_id do
      query ["ZADD", key, now, client_id]
      case get_local client_id do
        nil ->
          # Assume that a client from another cluster member is reconnecting.
          {:ok, pid} = Pixie.ClientSupervisor.start_child client_id
          pid
        pid -> pid
      end
    end
  end

  def ping client_id do
    if is_valid_client? client_id do
      query ["ZADD", key, now, client_id]
    end
  end

  def get_local client_id do
    if is_valid_client? client_id do
      Pixie.ClientSupervisor.whereis client_id
    end
  end

  def list do
    {:ok, client_ids} = query ["ZRANGEBYSCORE", key, cutoff, "+inf"]
    client_ids
  end

  defp key do
    cluster_namespace("clients")
  end

  defp is_valid_client? client_id do
    valid = case query ["ZSCORE", key, client_id] do
      {:ok, score} when is_binary(score)->
        score = String.to_integer score
        score >= cutoff
      _ ->
        false
    end

    unless valid, do: Pixie.Backend.destroy_client(client_id, "Client is no longer valid.")

    valid
  end

  defp now do
    Time.now |> Time.to_usecs
  end

  defp cutoff do
    Time.now |> Time.sub(Time.from(Pixie.timeout * 1.6, :msecs)) |> Time.to_usecs
  end

end
