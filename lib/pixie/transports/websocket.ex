defmodule Pixie.Transport.Websocket do
  use Pixie.Transport.Stream

  def close(adapter, _opts) when is_pid(adapter) do
    send adapter, :close
    :ok
  end
  def close(_,_), do: :ok

  def deliver {adapter, messages, opts} do
    send adapter, {:deliver, messages}
    {adapter, [], opts}
  end

  def connect_reply _state do
    :ok
  end
end
