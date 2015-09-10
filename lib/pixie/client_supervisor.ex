defmodule Pixie.ClientSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init [] do
    supervise([worker(Pixie.Client, [], restart: :transient)], strategy: :simple_one_for_one)
  end

  def start_child client_id do
    Supervisor.start_child __MODULE__, [client_id]
  end

  def terminate_child id do
    pid = whereis(id)
    Supervisor.terminate_child __MODULE__, pid
  end

  def whereis id do
    case :gproc.whereis_name {:n, :l, {Pixie.Client, id}} do
      :undefined -> nil
      pid        -> pid
    end
  end

  def all do
    :gproc.select([{{{:n, :l, {Pixie.Client, :"$1"}}, :_, :_}, [], [:"$1"]}])
  end
end
