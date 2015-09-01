defmodule Pixie.Backend.ETS do
  use Pixie.Backend
  use GenServer
  require Logger

  @moduledoc """
  This is the default persistence backend for Pixie, which stores data in an
  ETS table, which means it will only persist as long as this process is
  running.

  More information about ETS can be found
  [in the Elixir ETS docs](http://elixir-lang.org/getting-started/mix-otp/ets.html).
  """

  def start_link options do
    GenServer.start_link __MODULE__, options, name: __MODULE__
  end

  def init _options do
    table = :ets.new __MODULE__, [:set, :protected, :named_table, read_concurrency: true]
    :ets.insert table, default_state
    Process.flag :trap_exit, true
    {:ok, table}
  end

  def generate_namespace length do
    GenServer.call __MODULE__, {:generate_namespace, length}
  end

  def release_namespace namespace do
    GenServer.call __MODULE__, {:release_namespace, namespace}
  end

  def create_client do
    GenServer.call __MODULE__, :create_client
  end

  def get_client client_id do
    key = "client:#{client_id}"
    case :ets.lookup __MODULE__, key do
      [{^key, client}] -> client
      _ -> nil
    end
  end

  def destroy_client client_id, reason do
    GenServer.call __MODULE__, {:destroy_client, client_id, reason}
  end

  def subscribe client_id, channel_name do
    client_key = "client:#{client_id}"
    case :ets.lookup __MODULE__, client_key do
      [{^client_key, _client}] ->
        GenServer.call __MODULE__, {:subscribe, client_id, channel_name}
      _ -> :ok
    end
  end

  def unsubscribe client_id, channel_name do
    client_key = "client:#{client_id}"
    case :ets.lookup __MODULE__, client_key do
      [{^client_key, _client}] ->
        GenServer.call __MODULE__, {:unsubscribe, client_id, channel_name}
      _ -> :ok
    end
  end

  def subscribed_to client_id do
    client_subs_key = "client_subscriptions:#{client_id}"
    case :ets.lookup __MODULE__, client_subs_key do
      [{^client_subs_key,subs}] -> subs
      _ -> []
    end
  end

  def subscribers_of channel_pattern do
    case :ets.lookup __MODULE__, "all_channels" do
      [{"all_channels", channels}] ->
        # Reduce all subscribed clients of all matching channels to a single
        # set so that each client only receives the message once.
        Enum.reduce channels, HashSet.new, fn(channel_name, set)->
          matcher = compiled_matcher_for channel_name
          if channel_matches? matcher, channel_pattern do
            Set.union set, get_set("channel_subscriptions:#{channel_name}")
          else
            set
          end
        end
      _ -> HashSet.new
    end
  end

  def client_subscribed? client_id, channel_name do
    key = "client_subscriptions:#{client_id}"
    case :ets.lookup __MODULE__, key do
      [{^key, channels}] ->
        Set.member? channels, channel_name
      _ -> false
    end
  end

  def queue_for client_id, messages do
    client_key = "client:#{client_id}"
    case :ets.lookup __MODULE__, client_key do
      [{^client_key, _client}] ->
        GenServer.call __MODULE__, {:queue_messages, client_id, messages}
      _ -> :ok
    end
  end

  def dequeue_for client_id do
    queue_key = "queue_of:#{client_id}"
    case :ets.lookup __MODULE__, queue_key do
      [{^queue_key, messages}] ->
        GenServer.cast __MODULE__, {:dequeue_messages, client_id, Enum.count(messages)}
        messages
      _ -> []
    end
  end

  def handle_call {:generate_namespace, length}, _from, table do
    id = generate_unique_namespace length
    {:reply, id, table}
  end

  def handle_call {:release_namespace, namespace}, _from, table do
    delete_from_set :namespaces, namespace
    {:reply, :ok, table}
  end

  def handle_call :create_client, _from, table do
    {client_id, client} = do_create_client
    {:reply, {client_id, client}, table}
  end

  def handle_call {:destroy_client, client_id, reason}, _from, table do
    do_destroy_client client_id, reason
    {:reply, :ok, table}
  end

  def handle_call {:subscribe, client_id, channel_name}, _from, table do
    add_to_set "client_subscriptions:#{client_id}", channel_name
    case add_to_set "channel_subscriptions:#{channel_name}", client_id do
      1 -> create_channel channel_name
      _ -> nil
    end
    Logger.info "[#{client_id}]: Subscribed #{channel_name}"
    {:reply, :ok, table}
  end

  def handle_call {:unsubscribe, client_id, channel_name}, _from, table do
    do_unsubscribe client_id, channel_name
    Logger.info "[#{client_id}]: Unsubscribed #{channel_name}"
    {:reply, :ok, table}
  end

  def handle_call {:queue_messages, client_id, messages}, _from, table do
    queue_key = "queue_of:#{client_id}"
    queue = case :ets.lookup __MODULE__, queue_key do
      [{^queue_key, queue}] -> queue
      _               -> []
    end
    queue = queue ++ messages
    :ets.insert __MODULE__, [{queue_key, queue}]
    {:reply, :ok, table}
  end

  def handle_cast {:dequeue_messages, client_id, message_count}, table do
    queue_key = "queue_of:#{client_id}"
    case :ets.lookup __MODULE__, queue_key do
      [{^queue_key, queue}] ->
        queue = Enum.drop queue, message_count
        if Enum.empty? queue do
          :ets.delete __MODULE__, queue_key
        else
          :ets.insert __MODULE__, [{queue_key, queue}]
        end
      _ -> nil
    end

    {:noreply, table}
  end

  def terminate _reason, _table do
    Enum.each get_set("all_clients"), fn(client_id) ->
      do_destroy_client client_id, "Backend exiting"
    end
    :ok
  end

  def do_create_client do
    client_id  = generate_unique_namespace @default_id_length
    client_key = "client:#{client_id}"
    {:ok, client} = Pixie.Supervisor.add_worker Pixie.Client, client_key, [client_id]
    :ets.insert __MODULE__, [{client_key, client}]
    add_to_set "all_clients", client_id
    Logger.info "[#{client_id}]: Client created."
    {client_id, client}
  end

  def do_destroy_client client_id, reason do
    client_key = "client:#{client_id}"
    delete_from_set "all_clients", client_id
    :ets.delete __MODULE__, client_key
    subs = subscribed_to client_id
    Enum.each subs, fn(channel)->
      do_unsubscribe client_id, channel
    end
    Logger.debug "[#{client_id}]: Unsubscribed from #{Enum.count subs} channels"
    Logger.info "[#{client_id}]: Client destroyed: #{reason}"
    Pixie.Supervisor.terminate_worker client_key
    Pixie.Supervisor.terminate_worker "transport:#{client_id}"
  end

  def create_channel channel_name do
    add_to_set "all_channels", channel_name
    :ets.insert __MODULE__, [{"channel_matcher:#{channel_name}", compile_channel_matcher(channel_name)}]
  end

  defp destroy_channel channel_name do
    delete_from_set "all_channels", channel_name
    :ets.delete __MODULE__, "channel_matcher:#{channel_name}"
  end

  defp do_unsubscribe client_id, channel_name do
    delete_from_set "client_subscriptions:#{client_id}", channel_name
    case delete_from_set "channel_subscriptions:#{channel_name}", client_id do
      0 -> destroy_channel channel_name
      _ -> nil
    end
  end

  defp compiled_matcher_for channel_name do
    key = "channel_matcher:#{channel_name}"
    case :ets.lookup __MODULE__, key do
      [{^key, matcher}] -> matcher
      _ -> compile_channel_matcher(channel_name)
    end
  end

  defp add_to_set key, value do
    set = case :ets.lookup __MODULE__, key do
      [{^key, set}] -> set
      _             -> HashSet.new
    end
    set = Set.put set, value
    :ets.insert __MODULE__, [{key, set}]
    Set.size set
  end

  defp delete_from_set key, value do
    case :ets.lookup __MODULE__, key do
      [{^key, set}] ->
        set = Set.delete set, value
        if Set.size(set) == 0 do
          :ets.delete __MODULE__, key
        else
          :ets.insert __MODULE__, [{key, set}]
        end
        Set.size set
      _ -> 0
    end
  end

  defp get_set key do
    case :ets.lookup __MODULE__, key do
      [{^key, set}] -> set
      _ -> HashSet.new
    end
  end

  defp default_state do
    [
      namespaces: HashSet.new,
    ]
  end

  defp generate_unique_namespace length do
    id = Pixie.Utils.RandomId.generate length
    used = get_set :namespaces
    if Set.member? used, id do
      generate_unique_namespace length
    else
      add_to_set :namespaces, id
      id
    end
  end
end
