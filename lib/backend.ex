defmodule Pixie.Backend do
  def start_link name, options do
    module = Module.concat [:Pixie, :Backend, name]
    apply(module, :start_link, [Pixie.Backend, options])
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

  def create_client do
    GenServer.call __MODULE__, :create_client
  end

  def get_client client_id do
    GenServer.call __MODULE__, {:get_client, client_id}
  end

  def destroy_client client do
    GenServer.cast __MODULE__, {:destroy_client, client}
  end
end
