defmodule Pixie.Transport.LongPolling do
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

  # Long polling doesn't stray from the default advice
  def handle_call {:advice, advice}, _from, state do
    {:reply, advice, state}
  end

  # Await messages to send back to the adapter, unless there's already
  # an adapter process waiting for it.
  def handle_call {:await, messages}, from, {nil, queued_messages} do
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
  def handle_call {:await, messages}, from, {old, queued_messages} do
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

  defp enqueue_messages messages, {nil, queued_messages} do
    {nil, queued_messages ++ messages}
  end

  defp enqueue_messages messages, {waiting_adapter, queued_messages} do
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
end
