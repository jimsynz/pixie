defmodule Pixie.Transport do
  import Pixie.Utils.String

  def get transport_name, client_id do
    id = "transport:#{client_id}"
    transport_name = transport_name
      |> String.split("-")
      |> Enum.join("_")
      |> camelize(true)

    module = Module.concat __MODULE__, transport_name
    Pixie.Supervisor.replace_worker module, id, []
  end

  def advice transport, advice do
    GenServer.call transport, {:advice, advice}
  end

  def await transport, events do
    GenServer.call transport, {:await, events}, Pixie.timeout * 2
  end

  def enqueue transport, events do
    GenServer.cast transport, {:enqueue, events}
  end
end
