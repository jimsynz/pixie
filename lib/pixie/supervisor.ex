defmodule Pixie.Supervisor do
  use Pixie.GenericSupervisor
  import Supervisor.Spec

  def children do
    backend_options = Pixie.backend_options
    backend_name    = Dict.get backend_options, :name
    backend_options = Dict.delete backend_options, :name

    children = [
      worker(Pixie.ExtensionRegistry, [Pixie.configured_extensions]),
      worker(Pixie.Monitor, [Pixie.configured_monitors]),
      worker(Pixie.JsonEncoderCache, [])
    ]

    children = case Application.get_env(:pixie, :start_backend, true) do
      false -> children
      true  -> children ++ [supervisor(Pixie.Backend, [backend_name, backend_options])]
    end

    children = case Application.get_env(:pixie, :start_subscriptions, true) do
      false -> children
      true  -> children ++ [supervisor(Pixie.LocalSubscriptionSupervisor, [])]
    end

    children = case Application.get_env(:pixie, :start_cowboy, false) do
      false -> children
      true  -> [worker(Pixie.Server, []) | children]
    end

    children
  end
end
