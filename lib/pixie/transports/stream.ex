defmodule Pixie.Transport.Stream do
  use Behaviour

  defmacro __using__(_opts) do
    quote do
      use GenServer

      def start_link do
        GenServer.start_link __MODULE__, []
      end

      def init [] do
        {:ok, {nil, [], []}}
      end

      def terminate _, state do
        dequeue_messages state
        :ok
      end

      def handle_call {:advice, advice}, _from, state do
        {:reply, update_advice(advice), state}
      end

      # Long polling doesn't stray from the default advice
      def update_advice advice do
        advice
      end

      def handle_call({:connect, messages, opts}, from, {old, queued_messages, old_opts}) when from != old do
        from = sanitize_from from
        if should_close? {from, opts}, {old, old_opts} do
          close old, opts
        end
        case enqueue_messages(messages, {from, queued_messages, opts}) do
          {nil, _, _}=state ->
            {:reply, connect_reply(state), state}
          state ->
            {:reply, connect_reply(state), state, Pixie.timeout}
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

      def enqueue_messages messages, {nil, queued_messages, opts} do
        {nil, queued_messages ++ messages, opts}
      end

      def enqueue_messages messages, {waiting_adapter, queued_messages, opts} do
        messages = queued_messages ++ messages
        if Pixie.Protocol.respond_immediately? messages do
          dequeue_messages {waiting_adapter, messages, opts}
        else
          {waiting_adapter, messages, opts}
        end
      end

      def dequeue_messages {nil, queued_messages, opts} do
        {nil, queued_messages, opts}
      end

      def dequeue_messages state do
        deliver state
      end

      defp sanitize_from from do
        case from do
          {from, _} when is_pid(from)->
            from
          from when is_pid(from)->
            from
          _ -> nil
        end
      end

      def should_close? {new, _new_opts}, {old, _old_opts} do
        new != old
      end

      defoverridable [
        start_link: 0,
        update_advice: 1,
        enqueue_messages: 2,
        dequeue_messages: 1,
        should_close?: 2
      ]
    end
  end

  @doc false
  defcallback start_link() :: {atom, pid}

  defcallback enqueue_messages(messages :: [map], {from :: pid | nil, queued_messages :: [map], opts :: list}) :: {nil | pid, list, list}

  defcallback dequeue_messages({waiting :: pid | nil, queued_messages :: [map], opts :: list :: {nil, list, list}}) :: {nil | pid, list, list}

  defcallback close(adapter :: pid, opts :: list) :: atom

  defcallback deliver({waiting :: pid | nil, queued_messages :: [map], opts :: list}) :: {pid, list, list}

  defcallback should_close?({new_pid :: pid, new_opts :: []}, {old_pid :: pid, old_opts :: []}) :: atom

  defcallback connect_reply({pid :: pid, queued_messages :: [map], opts :: list}) :: any
end
