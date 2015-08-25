defmodule Pixie.Backend.Memory do
  use GenServer

  def start_link name, opts do
    GenServer.start_link __MODULE__, opts, name: name
  end

  def init(_), do: init
  def init do
    {:ok, %{
        namespaces: HashSet.new
      }}
  end

  def handle_call {:generate_namespace, length}, _from, %{namespaces: used}=state do
    {id, used} = generate_id used, length
    {:reply, id, %{state | namespaces: used}}
  end

  def handle_call :stop, from, state do
    GenServer.reply(from, :ok)
    {:stop, :normal, state}
  end

  def handle_cast {:release_namespace, namespace}, %{namespaces: used}=state do
    used = Set.delete used, namespace
    {:noreply, %{state | namespaces: used}}
  end

  def terminate _reason, _state do
    try do
      self |> Process.info(:registered_name) |> elem(1) |> Process.unregister
    rescue
      _ -> :ok
    end
    :ok
  end

  defp generate_id used, length do
    id = Pixie.UniqueId.generate length
    if Set.member? used, id do
      generate_id used, length
    else
      used = Set.put used, id
      {id, used}
    end
  end
end
