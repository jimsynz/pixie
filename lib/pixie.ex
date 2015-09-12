defmodule Pixie do
  use Application

  @default_timeout 25_000 # 25 seconds.
  # @default_transports ~w| long-polling cross-origin-long-polling callback-polling websocket eventsource |
  @default_transports ~w| long-polling cross-origin-long-polling callback-polling websocket |
  @default_backend [name: :ETS]
  @bayeux_version "1.0"

  @moduledoc """
  This module defines sensible defaults for all user configurable options, and
  provides a few helper functions, such as `publish` and `subscribe`.
  """

  @doc """
  Used to start the Pixie application by Mix.
  """
  def start(_,_), do: start
  def start do
    Pixie.Supervisor.start_link
  end

  @doc """
  Returns the currently running Pixie version.
  """
  def version do
    {:ok, version} = :application.get_key :pixie, :vsn
    to_string version
  end

  @doc """
  Returns the Bayeux version which Pixie implements. Currently `#{inspect @bayeux_version}`
  """
  def bayeux_version do
    @bayeux_version
  end

  @doc """
  Returns configured timeout in milliseconds.
  Defaults to `#{@default_timeout}` if nothing is configured.

  This value is used by Pixie to decide how long to wait between connect
  responses, and various multiples are used for client expiry timeouts,
  etc.
  """
  def timeout do
    Application.get_env(:pixie, :timeout, @default_timeout)
  end

  @doc """
  Returns either the configured backend options, or `#{inspect @default_backend}`.
  """
  def backend_options do
    case Application.get_env(:pixie, :backend) do
      []                      -> @default_backend
      opts when is_list(opts) -> opts
      _                       -> @default_backend
    end
  end

  @doc """
  The Bayeux protocol is undecided as to whether subscription requests should
  be responded to immediately, or can wait until either the next connect
  timeout, or the next message arrives for delivery to the client.

  By default Pixie waits to send subscribe requests, however if you have
  client's expecting an immediate response to subscriptions you can
  turn this on.

  An example of why you may want to send subscription responses immediately:

  ```javascript
  client = new Faye.Client("http://my.chat.server/pixie");
  client.subscribe("/foyer").then(function() {
    client.publish("/foyer", {message: "New user joined channel #foyer"})
  }, function(err) {
    alert("Unable to join #foyer: " + err)
  });
  ```

  See [Faye's documentation](http://faye.jcoglan.com/browser/subscribing.html)
  for more information.
  """
  def subscribe_immediately? do
    Application.get_env(:pixie, :subscribe_immediately, false)
  end

  @doc """
  Publish a `Pixie.Message.Publish`.
  """
  def publish %Pixie.Message.Publish{}=message do
    Pixie.Backend.publish message
  end

  @doc """
  Publish an arbitrary map. This converts the map to a `Pixie.Message.Publish`
  struct.
  """
  def publish %{}=message do
    publish Pixie.Message.Publish.init(message)
  end

  @doc """
  Publish a message to the specified channel.  This saves you from having to
  build the `Pixie.Message.Publish` yourself, you can simply specify the
  channel to publish to and an arbitrary map for the message's `data` property.
  """
  def publish channel, %{}=data do
    publish %{channel: channel, data: data}
  end

  @doc """
  Subscribe to a channel and call the provided function with messages.

  ```elixir
  {:ok, sub} = Pixie.subscribe "/my_awesome_channel", fn(message,_)->
    IO.inspect message
  end
  ```

  The function must take two arguments:
    - A message struct.
    - The subscription pid.
  """
  def subscribe channel_name, callback do
    Pixie.LocalSubscriptionSupervisor.add_worker Pixie.LocalSubscription, {channel_name, callback}, [channel_name, callback]
  end

  @doc """
  Cancel a local subscription.

  Example:

  ```elixir
  Pixie.subscribe "/only_one_please", fn(message,sub)->
    IO.inspect message
    Pixie.unsubscribe sub
  end
  ```
  """
  def unsubscribe pid do
    Pixie.LocalSubscription.unsubscribe pid
  end

  @doc """
  Returns a list of the configured extensions.
  """
  def configured_extensions do
    Application.get_env(:pixie, :extensions, [])
  end

  @doc """
  Returns a list of configured event monitors for use by `Pixie.Monitor`.
  """
  def configured_monitors do
    Application.get_env(:pixie, :monitors, [])
  end

  @doc """
  Returns a list of the currently enabled transports.
  This can be configured with:

  ```elixir
  config :pixie, :enabled_transports, ~w| long-polling websocket |
  ```

  Defaults to `#{inspect @default_transports}`.
  """
  def enabled_transports do
    Enum.into Application.get_env(:pixie, :enabled_transports, @default_transports), HashSet.new
  end
end
