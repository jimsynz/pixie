defmodule Pixie.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    backend_options = Application.get_env(:pixie, :backend, [name: :Memory])
    backend_name    = Dict.get backend_options, :name
    backend_options = Dict.delete backend_options, :name

    children = [
      worker(Pixie.Timeouts, []),
      worker(Pixie.Backend, [backend_name, backend_options])
    ]

    children = case Application.get_env(:pixie, :start_cowboy, false) do
      true  -> [worker(Pixie.Server, []) | children]
      false -> children
    end

    supervise(children, strategy: :one_for_one)
  end
end
