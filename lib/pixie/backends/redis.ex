defmodule Pixie.Backend.Redis do
  use Pixie.Backend
  use Supervisor
  import Pixie.Utils.Backend
  require Logger

  @default_id_length 32
  @pool_size 5
  @default_redis_url "redis://localhost:6379"

  def start_link opts do
    Supervisor.start_link __MODULE__, opts, name: __MODULE__
  end

  def init opts do
    defaults = [
      pool_size: @pool_size,
      redis_url: @default_redis_url
    ]
    opts = Keyword.merge defaults, opts
    children = [
      supervisor(Pixie.TransportSupervisor, []),
      supervisor(__MODULE__.Pool, [opts]),
      supervisor(__MODULE__.Clients, []),
      worker(__MODULE__.Notifications, [opts]),
      worker(__MODULE__.ClientGC, [])
    ]

    supervise children, strategy: :one_for_one
  end

  def generate_namespace length do
    __MODULE__.Namespaces.generate_namespace length
  end

  def release_namespace namespace do
    __MODULE__.Namespaces.release_namespace namespace
  end

  def create_client do
    {client_id, pid} = __MODULE__.Clients.create
    Logger.info "[#{client_id}]: Client created."
    {client_id, pid}
  end

  def get_client client_id do
    __MODULE__.Clients.get client_id
  end

  def destroy_client client_id, reason do
    do_destroy_client client_id, reason
  end

  def ping_client client_id do
    __MODULE__.Clients.ping client_id
  end

  def subscribe client_id, channel_name do
    __MODULE__.Channels.create channel_name
    __MODULE__.ClientSubscriptions.subscribe client_id, channel_name
    __MODULE__.ChannelSubscriptions.subscribe channel_name, client_id
    Logger.info "[#{client_id}]: Subscribed #{channel_name}"
  end

  def unsubscribe client_id, channel_name do
    do_unsubscribe client_id, channel_name
    Logger.info "[#{client_id}]: Unsubscribed #{channel_name}"
  end

  def subscribed_to client_id do
    __MODULE__.ClientSubscriptions.get client_id
  end

  def subscribers_of channel_pattern do
    __MODULE__.Channels.list
      |> Enum.reduce HashSet.new, fn
        ({channel_name, matcher}, set) ->
          if channel_matches? matcher, channel_pattern do
            subscribers = __MODULE__.ChannelSubscriptions.get channel_name
            subscribers = Enum.into subscribers, HashSet.new
            Set.union set, subscribers
          else
            set
          end
      end
  end

  def client_subscribed? client_id, channel_name do
    __MODULE__.ClientSubscriptions.subscribed? client_id, channel_name
  end

  def queue_for client_id, messages do
    __MODULE__.MessageQueue.queue client_id, messages
  end

  def dequeue_for client_id do
    __MODULE__.MessageQueue.dequeue client_id
  end

  defp do_destroy_client client_id, reason do
    subs = __MODULE__.ClientSubscriptions.get(client_id)
    Enum.each subs, fn(channel)->
      do_unsubscribe client_id, channel
    end
    __MODULE__.MessageQueue.destroy client_id
    __MODULE__.Namespaces.release_namespace client_id
    Logger.debug "[#{client_id}]: Unsubscribed from #{Enum.count subs} channels"
    Logger.info "[#{client_id}]: Client destroyed: #{reason}"
    __MODULE__.Clients.destroy client_id
    Pixie.TransportSupervisor.terminate_worker client_id
  end

  defp do_unsubscribe client_id, channel_name do
    __MODULE__.ClientSubscriptions.unsubscribe client_id, channel_name
    __MODULE__.ChannelSubscriptions.unsubscribe channel_name, client_id
    if __MODULE__.ChannelSubscriptions.subscriber_count(channel_name) == 0 do
      __MODULE__.Channels.destroy channel_name
    end
  end
end
