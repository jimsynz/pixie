defmodule Pixie.Backend do
  import Pixie.Utils

  # Default to using the Memory backend if none is specified.
  def start_link, do: start_link :Memory

  def start_link name do
    module = Module.concat [:Pixie, :Backend, camelize(name, true)]
    apply(module, :start_link, [[name: Pixie.Backend]])
  end

  def stop do
    GenServer.call __MODULE__, :stop
  end

  def generate_namespace, do: generate_namespace(32)
  def generate_namespace length do
    GenServer.call __MODULE__, {:generate_namespace, length}
  end

  def release_namespace namespace do
    GenServer.cast __MODULE__, {:release_namespace, namespace}
  end

end
