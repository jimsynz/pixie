defmodule Pixie.Backend.Redis.Connection do
  use GenServer

  def start_link redis_url do
    GenServer.start_link __MODULE__, redis_url
  end

  def init redis_url do
    Process.flag :trap_exit, true
    config = Exredis.ConnectionString.parse redis_url
    {:ok, {:disconnected, config}}
  end

  def conn pid do
    GenServer.call pid, :conn
  end

  def handle_call :conn, _, {:disconnected, c} do
    case Exredis.start_link c.host, c.port, c.db, c.password do
      {:ok, pid} ->
        {:reply, {:ok, pid}, {pid, c}}
      {:error, e} ->
        {:reply, {:error, e}, {:disconnected, c}}
    end
  end

  def handle_call :conn, _, {pid, config} do
    {:reply, {:ok, pid}, {pid, config}}
  end

  def handle_info {:EXIT, pid, _}, {pid, config} do
    {:noreply, {:disconnected, config}}
  end

  def handle_info _, state do
    {:noreply, state}
  end

  def terminate _reason, {:disconnected, _} do
    :ok
  end

  def terminate _reason, {pid, _} do
    Exredis.stop pid
    :ok
  end
end
