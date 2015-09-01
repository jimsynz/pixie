defmodule Pixie.Transport.Eventsource do
  use Pixie.Transport.Stream
  import Plug.Conn

  def close(adapter, _opts) when is_pid(adapter) do
    # Process.exit(adapter, :normal)
    :ok
  end

  def close(_,_), do: :ok

  def deliver({_, messages, _}=state) when is_list(messages) do
    Enum.reduce messages, state, fn(message, {a, _, o})->
      deliver {a, message, o}
    end
  end

  def deliver {adapter, message, [conn: conn]} do
    event = %{
      "id"   => :erlang.unique_integer([:positive, :monotonic]),
      "data" => Poison.encode!(message)
    }
    event = Enum.reduce event, "", fn({key, value}, str)->
      str ++ "#{key}: #{value}\r\n"
    end
    event = event ++ "\r\n"
    {:ok, conn} = chunk conn, event
    {adapter, [], [conn: conn]}
  end

  def should_close? {_new_pid, [conn: new_conn]}, {_old, [conn: old_conn]} do
    new_conn.owner != old_conn.owner
  end

  def should_close?(_,_), do: false

  def connect_reply {_, _, [conn: conn]} do
    conn
  end

  def connect_reply _ do
    :ok
  end
end
