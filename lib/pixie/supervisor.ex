defmodule Pixie.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def add_worker module, id, args do
    case Supervisor.start_child __MODULE__, worker_spec(module, id, args) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        {:ok, pid}
      other ->
        other
    end
  end

  def terminate_worker id do
    Supervisor.terminate_child __MODULE__, id
    Supervisor.delete_child __MODULE__, id
  end

  def replace_worker module, id, args do
    terminate_worker id
    add_worker module, id, args
  end

  def init([]) do
    backend_options = Pixie.backend_options
    backend_name    = Dict.get backend_options, :name
    backend_options = Dict.delete backend_options, :name

    children = [
      worker(Pixie.Timeouts, []),
      worker(Pixie.ExtensionRegistry, [Pixie.configured_extensions]),
      worker(Pixie.Backend, [backend_name, backend_options])
    ]

    children = case Application.get_env(:pixie, :start_cowboy, false) do
      true  -> [worker(Pixie.Server, []) | children]
      false -> children
    end

    supervise(children, strategy: :one_for_one)
  end

  defp worker_spec module, id, args do
    {id, {module, :start_link, args}, :transient, 5000, :worker, [module]}
  end
end
