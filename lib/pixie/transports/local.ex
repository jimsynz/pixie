defmodule Pixie.Transport.Local do
  use Pixie.Transport.Default

  def enqueue_messages messages, {client, []} do
    dequeue_messages {client, messages}
  end

  def enqueue_messages messages, {client, queued_messages} do
    messages = queued_messages ++ messages
    dequeue_messages {client, messages}
  end

  def dequeue_messages {client, queued_messages} do
    GenServer.reply(client, queued_messages)
    {client, []}
  end
end
