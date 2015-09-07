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
      import Pixie.Utils.Backend
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
  defcallback create_client :: {client_id :: String.t, pid}

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

  @doc """
  Deliver messages to clients, local or otherwise.
  """
  defcallback deliver(client_id :: String.t, messages :: list) :: atom

  @doc """
  Called by the Pixie supervisor to start the selected backend.
  """
  def start_link name, options do
    module = Module.concat [:Pixie, :Backend, name]
    apply(module, :start_link, [options])
  end

  # FIXME
  # This is all really horrible, but I can't think of a better way of doing it
  # at the moment.  If you have a better idea then please, send me a PR.

  @doc """
  Generate a unique identifier which can be used as a `client_id`, etc.
  """
  def generate_namespace, do: generate_namespace(@default_id_length)
  def generate_namespace(length), do: apply_to_backend(:generate_namespace, [length])

  @doc """
  Release a namespace, which means it's theoretically possible to reuse it.
  """
  def release_namespace(namespace), do: apply_to_backend(:release_namespace, [namespace])

  @doc """
  Create a client. Used internally by the protocol, you probably will never
  call this.
  """
  def create_client, do: apply_to_backend(:create_client, [])

  @doc """
  Retrieve the pid of the client registered to the provided `client_id`.
  """
  def get_client(client_id), do: apply_to_backend(:get_client, [client_id])

  @doc """
  Destroy the specified client registered to the provided `client_id`.

  This function has the following side effects:
    - unsubscribes the client from all their subscribed channels.
    - destroys any channels with no subscribers left.
    - destroys any queued messages for the client.
    - releases the client_id namespace.
    - destroys the client process.
    - destroys the transport process (which has the side-effect of
      disconnecting the user).
  """
  def destroy_client(client_id), do: apply_to_backend(:destroy_client, [client_id])
  def destroy_client(client_id, reason), do: apply_to_backend(:destroy_client, [client_id, reason])

  @doc """
  Ping the specified client.  This is specifically used for backends which
  will expire clients for inactivity (ie Redis).
  """
  def ping_client(client_id), do: apply_to_backend(:ping_client, [client_id])

  @doc """
  Subscribe the specified client to the specified channel.
  """
  def subscribe(client_id, channel_name), do: apply_to_backend(:subscribe, [client_id, channel_name])
  @doc """
  Unsubscribe the specified client from the specified channel.

  This function has the following side effects:
    - destroys any channels with no subscribers left.
  """
  def unsubscribe(client_id, channel_name), do: apply_to_backend(:unsubscribe, [client_id, channel_name])

  @doc """
  Returns a `HashSet` containing the list of `client_id`s subscribed to the
  provided channel.
  """
  def subscribers_of(channel_name), do: apply_to_backend(:subscribers_of, [channel_name])

  @doc """
  Returns a `HashSet` containing the list of channels the client is subscribed to.
  """
  def subscribed_to(client_id), do: apply_to_backend(:subscribed_to, [client_id])

  @doc """
  Responds `true` or `false` depending on whether the `client_id` is subscribed
  to the given channel.
  """
  def client_subscribed?(client_id, channel_name), do: apply_to_backend(:client_subscribed?, [client_id, channel_name])

  @doc """
  Queue messages for delivery to the specified client.  This is usually only
  called by the protocol when publishing messages for clients which are either
  in-between polls or located on another Pixie instance. Use `publish` instead.
  """
  def queue_for(client_id, messages), do: apply_to_backend(:queue_for, [client_id, messages])

  @doc """
  Dequeue any messages awaiting delivery to the specified client.  This is
  usually only called by the protocol when a client reconnects to retrieve
  any messages that arrived while the client was disconnected.
  Use `publish` instead.
  """
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
        messages = Enum.reverse(messages)
        apply_to_backend :deliver, [client_id, messages]
    end

    # Then we publish the rest, if any.
    publish rest
    :ok
  end

  def publish(message), do: publish([message])

  defp apply_to_backend(fun, args) when is_list(args) do
    name = Keyword.get Pixie.backend_options, :name
    mod  = Module.concat [Pixie.Backend, name]
    apply(mod, fun, args)
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
        message = Pixie.ExtensionRegistry.outgoing message
        Enum.reduce subscribers, cache, fn
          (subscriber, cache)->
            queue = Map.get cache, subscriber, []
            queue = [message | queue]
            Map.put cache, subscriber, queue
        end
    end
  end
end
