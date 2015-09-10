defmodule Pixie.TransportSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  def init [] do
    supervise([worker(Pixie.Transport, [], restart: :temporary)], strategy: :simple_one_for_one)
  end

  def start_child transport_name, client_id do
    Supervisor.start_child __MODULE__, [transport_name, client_id]
  end

  def terminate_child id do
    pid = whereis(id)
    Supervisor.terminate_child __MODULE__, pid
  end

  def replace_child transport_name, client_id do
    terminate_child client_id
    start_child transport_name, client_id
  end

  def whereis id do
    case :gproc.whereis_name {:n, :l, {Pixie.Transport, id}} do
      :undefined -> nil
      pid        -> pid
    end
  end

  def all do
    :gproc.select([{{{:n, :l, {Pixie.Transport, :"$1"}}, :_, :_}, [], [:"$1"]}])
  end
end
