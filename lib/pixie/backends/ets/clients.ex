defmodule Pixie.Backend.ETS.Clients do
  @moduledoc """
  This process manages the generation and removal of client processes.
  """

  def create do
    client_id = Pixie.Backend.generate_namespace
    {:ok, pid} = Pixie.ClientSupervisor.start_child client_id
    {client_id, pid}
  end

  def destroy client_id do
    Pixie.ClientSupervisor.terminate_child client_id
  end

  def get client_id do
    Pixie.ClientSupervisor.whereis client_id
  end

  def list do
    Pixie.ClientSupervisor.all
  end
end
