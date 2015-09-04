defmodule Pixie.Backend.Redis.Notifications do
  import Pixie.Backend.Redis.Connection
  use GenServer

  def start_link opts do
    GenServer.start_link __MODULE__, opts
  end

  def trigger client_id do
    query ["PUBLISH", trigger_key, client_id]
  end

  def init opts do
    redis_url = Keyword.get(opts, :redis_url)
    c = Exredis.ConnectionString.parse redis_url
    {:ok, pid} = Exredis.Sub.start_link c.host, c.port, c.password
    me = self
    Exredis.Sub.subscribe pid, trigger_key, fn(msg)->
      send me, msg
    end
    {:ok, [pid: pid]}
  end

  def handle_info {:message, _key, client_id, _pid}, state do
    case Pixie.Backend.Redis.Clients.get_local client_id do
      nil -> nil
      client ->
        Pixie.Client.dequeue client
    end
    {:noreply, state}
  end

  # We don't care about any other messages from the pubsub server.
  def handle_info _, state do
    {:noreply, state}
  end

  def trigger_key do
    cluster_namespace("message_triggers")
  end

end
