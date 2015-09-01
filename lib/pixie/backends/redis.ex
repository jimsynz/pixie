defmodule Pixie.Backend.Redis do
  # use Pixie.Backend
  use Supervisor
  @pool_size 5
  @default_redis_url "redis://localhost:6379"
  @default_id_length 32

  def start_link opts do
    Supervisor.start_link __MODULE__, opts, name: __MODULE__
  end

  def init opts do
    pool_name   = Pixie.Backend.Redis.Pool
    pool_opts = [
      name:          {:local, pool_name},
      worker_module: Pixie.Backend.Redis.Connection,
      size:          Keyword.get(opts, :pool_size, @pool_size),
      max_overflow:  0
    ]

    children = [
      :poolboy.child_spec(pool_name, pool_opts, Keyword.get(opts, :redis_url, @default_redis_url))
      worker(Pixie.Backend.Redis.Subscription, [redis_namespace("destroy_client")])
      worker(Pixie.Backend.Redis.Subscription, [redis_namespace("message")])
    ]

    supervise children, strategy: :one_for_all
  end

  def generate_namespace length do
    id   = Pixie.Utils.RandomId.generate length
    key  = redis_namespace "namespaces"

    case redis ["SISMEMBER", key, id] do
      {:ok, "1"} ->
        generate_namespace length

      {:ok, "0"} ->
        {:ok, "1"} = redis ["SADD", key, id]

      error ->
        error
    end
  end

  def release_namespace namespace do
    key = redis_namespace "namespaces"

    case redis ["SREM", key, namespace] do
      {:ok, _} -> :ok
      error    -> error
    end
  end

  def create_client do
    client_id = generate_namespace @default_id_length
    worker_key = "client:#{client_id}"
    {:ok, client} = Pixie.Supervisor.add_worker Pixie.Client, worker_key, [client_id]

    case redis ["SADD", redis_namespace("all_clients"), client_id] do
      {:ok, _} -> :ok
      error    -> error
    end
  end

  def get_client client_id do
    worker_key = "client:#{client_id}"
    {:ok, client} = Pixie.Supervisor.add_worker Pixie.Client, worker_key, [client_id]
    client
  end

  def destroy_client client_id do
    redis ["PUBLISH", redis_namespace("destroy_client"), client_id]
  end

  def redis commands do
    :poolboy.transaction Pixie.Backend.Redis.Pool, fn worker_pid ->
      case Pixie.Backend.Redis.Connection.conn worker_pid do
        {:ok, conn_pid}->
          case Exredis.query(conn_pid, commands) do
            {:error, _}=error -> error
            result            -> {:ok, result}
          end
        error -> error
      end
    end
  end

  defp redis_namespace nil do
    "pixie:#{Mix.env}"
  end
  defp redis_namespace namespace do
    "#{redis_namespace nil}:namespace"
  end
end
