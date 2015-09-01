defmodule Pixie.Backend do
  use Behaviour
  @default_id_length 32
  @max_messages_per_publish 256

  @moduledoc """
  Used to implement the persistence backend for Pixie.
  """

  defmacro __using__(_opts) do
    quote do
      @behaviour Pixie.Backend
      import Pixie.Backend.Utils
      @default_id_length 32

      def generate_namespace, do: generate_namespace(@default_id_length)
      def destroy_client(client_id), do: destroy_client(client_id, "No reason.")

      defoverridable [generate_namespace: 0, destroy_client: 1]
    end
  end

  @doc """
  Used to start your Backend's process.
  """
  defcallback start_link(options :: any) :: {atom, pid}

  @doc """
  Used to create a unique identifier for client ID's, etc.
  """
  defcallback generate_namespace(length :: integer) :: String.t

  @doc """
  Used to release a unique identifier that's no longer in use.
  """
  defcallback release_namespace(namespace :: String.t) :: atom

  @doc """
  Create a new `Pixie.Client` process.
  """
  defcallback create_client :: pid

  @doc """
  Retrieve the process of a client by it's ID.
  """
  defcallback get_client(client_id :: String.t) :: pid

  @doc """
  Destroy a client.
  """
  defcallback destroy_client(client_id :: String.t, reason :: atom)

  @doc """
  Subscribe a client to a channel
  """
  defcallback subscribe(client_id :: String.t, channel_name :: String.t) :: atom

  @doc """
  Unsubscribe a client from a channel
  """
  defcallback unsubscribe(client_id :: String.t, channel_name :: String.t | [String.t]) :: atom

  @doc """
  Retrieve the unique subscribers of channels matching the channel pattern.
  """
  defcallback subscribers_of(channel_pattern :: String.t) :: [pid]

  @doc """
  Retrieve the channels that the client is subscribed to.
  """
  defcallback subscribed_to(client_id :: String.t) :: [String.t]

  @doc """
  Check whether the client is subscribed to the mentioned channel.
  """
  defcallback client_subscribed?(client_id :: String.t, channel_name :: String.t) :: :atom

  @doc """
  Temporarily store messages for a client if it's transport is unconnected.
  """
  defcallback queue_for(client_id :: String.t, messages :: [map]) :: atom

  @doc """
  Dequeue any stored messages for a given client.
  """
  defcallback dequeue_for(client_id :: String.t) :: [map]

  def start_link name, options do
    module = Module.concat [:Pixie, :Backend, name]
    :ets.new __MODULE__, [:set, :protected, :named_table, read_concurrency: true]
    :ets.insert __MODULE__, [configured_backend: module]
    apply(module, :start_link, [options])
  end

  # FIXME
  # This is all really horrible, but I can't think of a better way of doing it
  # at the moment.  If you have a better idea then please, send me a PR.
  def generate_namespace, do: generate_namespace(@default_id_length)
  def generate_namespace(length), do: apply_to_backend(:generate_namespace, [length])
  def release_namespace(namespace), do: apply_to_backend(:release_namespace, [namespace])
  def create_client, do: apply_to_backend(:create_client, [])
  def get_client(client_id), do: apply_to_backend(:get_client, [client_id])
  def destroy_client(client_id), do: apply_to_backend(:destroy_client, [client_id])
  def destroy_client(client_id, reason), do: apply_to_backend(:destroy_client, [client_id, reason])
  def subscribe(client_id, channel_name), do: apply_to_backend(:subscribe, [client_id, channel_name])
  def unsubscribe(client_id, channel_name), do: apply_to_backend(:unsubscribe, [client_id, channel_name])
  def subscribers_of(channel_name), do: apply_to_backend(:subscribers_of, [channel_name])
  def subscribed_to(client_id), do: apply_to_backend(:subscribed_to, [client_id])
  def client_subscribed?(client_id, channel_name), do: apply_to_backend(:client_subscribed?, [client_id, channel_name])
  def queue_for(client_id, messages), do: apply_to_backend(:queue_for, [client_id, messages])
  def dequeue_for(client_id), do: apply_to_backend(:dequeue_for, [client_id])

  @doc """
  Publishes a collection of messages to all their receiving clients.
  """
  def publish([]), do: :ok
  def publish(messages) when is_list(messages) do
    # First we take `@max_messages_per_publish` messages.
    {messages, rest} = Enum.split(messages, @max_messages_per_publish)

    # Then explode them by channel and group them by client
    # So that we can deliver as many messages as possible per
    # each `Pixie.Client.deliver` call.
    Enum.each messages_by_client_id(messages), fn
      ({client_id, messages})->
        client   = get_client client_id
        messages = Enum.reverse(messages)
        Pixie.Client.deliver client, messages
    end

    # Then we publish the rest, if any.
    publish rest
    :ok
  end

  def publish(message), do: publish([message])

  defp apply_to_backend(func, args) when is_list(args) do
    case :ets.lookup __MODULE__, :configured_backend do
      [{:configured_backend, module}] ->
        apply(module, func, args)
    end
  end

  # Cache the subscription lists for each channel we're delivering to
  defp subscribers_by_channel messages do
    Enum.reduce messages, %{}, fn
      (%{channel: channel_name}, cache)->
        if Map.has_key? cache, channel_name do
          cache
        else
          Map.put cache, channel_name, subscribers_of(channel_name)
        end
    end
  end

  # Explode the list of messages to a queue for every client that we
  # wish to deliver to.
  defp messages_by_client_id messages do
    Enum.reduce messages, %{}, fn
      (%{channel: channel_name}=message, cache)->
        subscribers = Map.get subscribers_by_channel(messages), channel_name
        Enum.reduce subscribers, cache, fn
          (subscriber, cache)->
            queue = Map.get cache, subscriber, []
            queue = [message | queue]
            Map.put cache, subscriber, queue
        end
    end
  end
end
