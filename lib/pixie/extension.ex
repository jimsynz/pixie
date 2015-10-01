defmodule Pixie.Extension do
  @moduledoc """
  Used to implement Bayeux extensions, which can be used to filter or change
  incoming messages and the responses sent back to the client.

  For example:
  ```elixir
  defmodule AuthenticationExtension do
    use Pixie.Extension

    def incoming %Event{message: %{ext: %{username: u, password: p}=message}}=event do
      case User.authenticate username, password do
        :ok ->
          %{event | message: %{message | ext: nil}}
        :error ->
          %{event | response: %{response | error: "Authentication Failed"}}
      end
    end

    def incoming %Event{}=event do
      %{event | response: %{response | error: "Authentication Failed"}}
    end
  ```

  Note that you *must* always provide a "catch all" function head that matches
  all other events and returns them - otherwise the runtime will start raising
  exceptions and generally make you feel sad.

  You can dynamically add your extension to the extension stack at runtime using
  `YourExtension.register` and `YourExtension.unregister`
  """

  defmacro __using__(_opts) do
    quote do
      @behaviour Pixie.Extension

      alias Pixie.Event
      alias Pixie.Protocol.Error

      def register do
        Pixie.ExtensionRegistry.register __MODULE__
      end

      def unregister do
        Pixie.ExtensionRegistry.unregister __MODULE__
      end

      defoverridable [register: 0, unregister: 0]
    end
  end

  @doc """
  Can be used to modify the `Pixie.Event` struct that is passed in.

  The incoming message is provided in the `message` property, whereas the
  response being sent back to the sending client is stored in the `response`
  property.

  Note that if you want to stop the message from being delivered then set it
  to `nil`, likewise if you want to stop a response being sent to the client.
  You must *always* return a Pixie.Event struct from `handle/1`.
  """
  @callback incoming(event :: Pixie.Event.t) :: Pixie.Event.t

  @doc """
  Can be used to modify an outgoing message before it is passed to the channel
  for final delivery to clients.

  If you wish to stop this message being delivered then return `nil` otherwise
  you must always return a message back to the caller.
  """
  @callback outgoing(message :: Pixie.Message.Publish.t) :: Pixie.Message.Publish.t
end
