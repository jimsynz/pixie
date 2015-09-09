defmodule Pixie.Transport.Default do
  use Behaviour

  defmacro __using__(_opts) do
    quote do
      use GenServer

      def start_link do
        GenServer.start_link __MODULE__, []
      end

      def init [] do
        {:ok, {nil, []}}
      end

      def terminate _, state do
        dequeue_messages state
        :ok
      end

      def handle_call {:advice, advice}, _from, state do
        {:reply, update_advice(advice), state}
      end

      def update_advice advice do
        advice
      end

      # Await messages to send back to the adapter, unless there's already
      # an adapter process waiting for it.
      def handle_call {:connect, messages}, from, {nil, queued_messages} do
        case enqueue_messages(messages, {from, queued_messages}) do
          {nil, _}=state ->
            {:noreply, state}
          state ->
            {:noreply, state, Pixie.timeout}
        end
      end

      # If a second adapter connects while we're still waiting for an old one
      # to timeout it will kill the timeout, so we send an empty reply to the
      # old adapter to get it to close it's connection then we run the usual
      # enqueuing logic.
      def handle_call {:connect, messages}, from, {old, queued_messages} do
        GenServer.reply old, []
        case enqueue_messages(messages, {from, queued_messages}) do
          {nil, _}=state ->
            {:noreply, state}
          state ->
            {:noreply, state, Pixie.timeout}
        end
      end

      def handle_call {:ensure_enqueue, messages}, state do
        {:reply, :ok, enqueue_messages(messages, state)}
      end

      def handle_cast {:enqueue, messages}, state do
        {:noreply, enqueue_messages(messages, state)}
      end

      def handle_info :timeout, state do
        {:noreply, dequeue_messages state}
      end

      def enqueue_messages messages, {nil, queued_messages} do
        {nil, queued_messages ++ messages}
      end

      def enqueue_messages messages, {waiting_adapter, queued_messages} do
        messages = queued_messages ++ messages
        if Pixie.Protocol.respond_immediately? messages do
          dequeue_messages {waiting_adapter, messages}
        else
          {waiting_adapter, messages}
        end
      end

      def dequeue_messages {nil, queued_messages} do
        {nil, queued_messages}
      end

      def dequeue_messages {waiting_adapter, queued_messages} do
        GenServer.reply(waiting_adapter, queued_messages)
        {nil, []}
      end

      defoverridable [
        start_link: 0,
        update_advice: 1,
        enqueue_messages: 2,
        dequeue_messages: 1
      ]
    end
  end

  @doc false
  defcallback start_link() :: {atom, pid}

  defcallback enqueue_messages(messages :: [map], {from :: pid | nil, queued_messages :: [map]}) :: {nil | pid, list}

  defcallback dequeue_messages({waiting :: pid | nil, queued_messages :: [map]}) :: {nil, list}
end
