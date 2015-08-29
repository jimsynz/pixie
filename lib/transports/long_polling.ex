defmodule Pixie.Transport.LongPolling do
  use GenServer
  alias Pixie.Event

  def start_link do
    GenServer.start_link __MODULE__, []
  end

  def init [] do
    {:ok, {nil, []}}
  end

  def terminate _, state do
    dequeue_events state
    :ok
  end

  # Long polling doesn't stray from the default advice
  def handle_call {:advice, advice}, _from, state do
    {:reply, advice, state}
  end

  # Await events to send back to the adapter, unless there's already
  # an adapter process waiting for it.
  def handle_call {:await, events}, from, {nil, queued_events} do
    case enqueue_events(events, {from, queued_events}) do
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
  def handle_call {:await, events}, from, {old, queued_events} do
    GenServer.reply old, []
    case enqueue_events(events, {from, queued_events}) do
      {nil, _}=state ->
        {:noreply, state}
      state ->
        {:noreply, state, Pixie.timeout}
    end
  end

  def handle_cast {:enqueue, events}, state do
    {:noreply, enqueue_events(events, state)}
  end

  def handle_info :timeout, state do
    {:noreply, dequeue_events state}
  end

  defp enqueue_events events, {nil, queued_events} do
    {nil, queued_events ++ events}
  end

  defp enqueue_events events, {waiting_adapter, queued_events} do
    events = queued_events ++ events
    if Event.respond_immediately? events do
      dequeue_events {waiting_adapter, events}
    else
      {waiting_adapter, events}
    end
  end

  def dequeue_events {nil, queued_events} do
    {nil, queued_events}
  end

  def dequeue_events {waiting_adapter, queued_events} do
    GenServer.reply(waiting_adapter, queued_events)
    {nil, []}
  end
end
