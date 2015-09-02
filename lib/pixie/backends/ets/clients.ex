defmodule Pixie.Backend.ETS.Clients do
  require Logger
  use Pixie.GenericSupervisor
  @moduledoc """
  This process manages the generation and removal of client processes.
  """

  def create do
    client_id = Pixie.Backend.generate_namespace
    {:ok, pid} = add_worker Pixie.Client, client_id, [client_id]
    {client_id, pid}
  end

  def destroy client_id do
    terminate_worker client_id
  end

  def get client_id do
    Supervisor.which_children(__MODULE__)
    |> Enum.find_value fn (worker)->
      case worker do
        {^client_id, pid, _, _} when is_pid(pid)-> pid
        _ -> nil
      end
    end
  end

  def list do
    Enum.filter_map Supervisor.which_children(__MODULE__),
      fn
        {client_id, pid, _, _} when is_binary(client_id) and is_pid(pid) -> true
        _ -> false
      end,
      fn
        {client_id, _, _, _} -> client_id
      end
  end
end
