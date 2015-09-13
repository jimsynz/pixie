defmodule Pixie.Monitor do
  use Timex
  use Behaviour

  @moduledoc """
  Allows you to monitor various events within Pixie.

  Internally Pixie.Monitor is implemented using GenEvent, so you're free to
  bypass using the Pixie.Monitor behaviour and use your own GenEvent if the
  need arises.

  Usage example:
  ```elixir
  defmodule MyMonitor do
    use Pixie.Monitor

    def created_channel channel_name, at do
      Logger.info "Channel \#\{channel_name} created at \#\{format at}"
    end

    def destroyed_channel channel_name, at do
      Logger.info "Channel \#\{channel_name} destroyed at \#\{format at}"
    end

    defp format timestamp do
      timestamp
        |> Date.from(:timestamp)
        |> DateFormat.format!("{UNIX}")
    end
  end
  ```
  """

  defmacro __using__(_opts) do
    quote do
      use GenEvent
      use Timex

      def handle_event({fun, args}, state) when is_atom(fun) and is_list(args) do
        apply __MODULE__, fun, args
        {:ok, state}
      end

      def created_client(_client_id, _at), do: :ok
      def destroyed_client(_client_id, _reason, _at), do: :ok
      def created_channel(_channel_name, _at), do: :ok
      def destroyed_channel(_channel_name, _at), do: :ok
      def client_subscribed(_client_id, _channel_name, _at), do: :ok
      def client_unsubscribed(_client_id, _channel_name, _at), do: :ok
      def received_message(_client_id, _message_id, _at), do: :ok
      def delivered_message(_client_id, _message_id, _at), do: :ok

      defoverridable [
        created_client: 2,
        destroyed_client: 3,
        created_channel: 2,
        destroyed_channel: 2,
        client_subscribed: 3,
        client_unsubscribed: 3,
        received_message: 3,
        delivered_message: 3
      ]
    end
  end

  @doc """
  Called when a new client is created during protocol handshake.
  """
  defcallback created_client(client_id :: binary, at :: {megasecs :: integer, seconds :: integer, microsecs :: integer}) :: atom

  @doc """
  Called when a client is destroyed - either by an explicit disconnect request
  from the client, or by a system generated timeout.
  """
  defcallback destroyed_client(client_id :: binary, reason :: binary | atom, at :: {megasecs :: integer, seconds :: integer, microsecs :: integer}) :: atom

  @doc """
  Called when a new channel is created - this happens when a client subscribes
  to it for the first time.
  """
  defcallback created_channel(channel_name :: binary, at :: {megasecs :: integer, seconds :: integer, microsecs :: integer}) :: atom

  @doc """
  Called when a channel is destroyed - this happens when the last client
  unsubscribes from it.
  """
  defcallback destroyed_channel(channel_name :: binary, at :: {megasecs :: integer, seconds :: integer, microsecs :: integer}) :: atom

  @doc """
  Called when a client subscribes to a channel.
  """
  defcallback client_subscribed(client_id :: binary, channel_name :: binary, at :: {megasecs :: integer, seconds :: integer, microsecs :: integer}) :: atom

  @doc """
  Called when a client unsubscribes from a channel.
  """
  defcallback client_unsubscribed(client_id :: binary, channel_name :: binary, at :: {megasecs :: integer, seconds :: integer, microsecs :: integer}) :: atom

  @doc """
  Called when a message is received with the ID of the message.

  Some caveats:

    - This function is only called when a publish message is received, not when
      any protocol messages, such as connect or subscribe are received.
    - Message IDs are only unique per client, not globally.
    - If the message was generated on the server (ie via `Pixie.publish/2`) then
      the Client ID is likely to be `nil`.
  """
  defcallback received_message(client_id :: binary, message_id :: binary, at :: {megasecs :: integer, seconds :: integer, microsecs :: integer}) :: atom

  @doc """
  Called when a message is delivered to a client.

  Some caveats:

    - This function is only called when a publish message is delivered, not when
      any protocol messages, such as connect or subscribe are.
    - Message IDs are only unique per client, not globally.
    - The Client ID is that of the *sender*, not the receiver.
    - If the message was generated on the server (ie via `Pixie.publish/2`) then
      the Client ID is likely to be `nil`.
    - You will likely receive a lot of delivered calls for each received call
      as one message published to a channel may be relayed to thousands of
      receivers.
  """
  defcallback delivered_message(client_id :: binary, message_id :: binary, at :: {megasecs :: integer, seconds :: integer, microsecs :: integer}) :: atom

  def start_link handlers do
    {:ok, pid} = GenEvent.start_link name: __MODULE__
    Enum.each handlers, fn
      {handler, args} ->
        add_handler handler, args
      handler ->
        add_handler handler, []
    end
    {:ok, pid}
  end

  @doc """
  Allows you to add a `Pixie.Monitor` or any other `GenEvent` handler to the
  event stream.  Expects the name of your handler module and any args which
  you wish to be provided to your module's `init/1` callback.
  """
  def add_handler handler, args \\ [] do
    GenEvent.add_handler __MODULE__, handler, args
  end

  @doc """
  Called by the backend when a new client is created either by protocol
  handshake, or via `Pixie.subscribe/2`
  """
  def created_client client_id do
    GenEvent.notify __MODULE__, {:created_client, [client_id, Time.now]}
  end

  @doc """
  Called by the backend when a client is destroyed, either by an expicit
  protocol disconnect or for a system generated reason, such as a timeout.
  """
  def destroyed_client client_id, reason \\ "Unknown reason" do
    GenEvent.notify __MODULE__, {:destroyed_client, [client_id, reason, Time.now]}
  end

  @doc """
  Called by the backend when a new channel is created.
  New channels are created when the first client subscribes to them.
  """
  def created_channel channel_name do
    GenEvent.notify __MODULE__, {:created_channel, [channel_name, Time.now]}
  end

  @doc """
  Called by the backend when a channel is destroyed.
  Channels are destroyed when the last client unsubscribes from them.
  """
  def destroyed_channel channel_name do
    GenEvent.notify __MODULE__, {:destroyed_channel, [channel_name, Time.now]}
  end

  @doc """
  Called by the backend when a client subscribes to a channel.
  """
  def client_subscribed client_id, channel_name do
    GenEvent.notify __MODULE__, {:client_subscribed, [client_id, channel_name, Time.now]}
  end

  @doc """
  Called by the backend when a client unsubscribes from a channel.
  """
  def client_unsubscribed client_id, channel_name do
    GenEvent.notify __MODULE__, {:client_unsubscribed, [client_id, channel_name, Time.now]}
  end

  @doc """
  Called whenever a new message is received for publication.
  This includes server-generated messages using `Pixie.publish/2`
  """
  def received_message %Pixie.Message.Publish{client_id: client_id, id: message_id} do
    GenEvent.notify __MODULE__, {:received_message, [client_id, message_id, Time.now]}
  end
  def received_message(_), do: :ok

  @doc """
  Called by adapters when a message is finally delivered to a client.
  """
  def delivered_message %Pixie.Message.Publish{client_id: client_id, id: message_id} do
    GenEvent.notify __MODULE__, {:delivered_message, [client_id, message_id, Time.now]}
  end
  def delivered_message(_), do: :ok

end
