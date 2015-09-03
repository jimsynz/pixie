defmodule Pixie.GenericSupervisor do
  defmacro __using__(_opts) do
    quote do
      use Supervisor
      import Supervisor.Spec

      def start_link do
        Supervisor.start_link __MODULE__, [], name: __MODULE__
      end

      def init [] do
        supervise children, strategy: strategy
      end

      def children, do: []
      def strategy, do: :one_for_one

      def add_worker module, id, args do
        case Supervisor.start_child __MODULE__, worker(module, args, id: id, restart: :transient) do
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

      defoverridable [children: 0, strategy: 0]
    end
  end
end
