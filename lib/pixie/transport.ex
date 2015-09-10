defmodule Pixie.Transport do
  import Pixie.Utils.String

  def start_link transport_name, client_id do
    transport_name
      |> module_from_name
      |> apply(:start_link, [client_id])
  end

  def advice transport, advice do
    GenServer.call transport, {:advice, advice}
  end

  def connect transport, messages do
    GenServer.call transport, {:connect, messages}, Pixie.timeout * 2
  end

  def enqueue _transport, [] do
    :ok
  end

  def enqueue transport, messages do
    GenServer.cast transport, {:enqueue, messages}
  end

  def ensure_enqueue transport, messages do
    GenServer.call transport, {:ensure_enqueue, messages}
  end

  defp module_from_name name do
    name = name
      |> String.split("-")
      |> Enum.join("_")
      |> camelize(true)

    Module.concat __MODULE__, name
  end
end
