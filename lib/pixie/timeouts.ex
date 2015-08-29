defmodule Pixie.Timeouts do
  defstruct timer_ref: nil, module: nil, function: nil, args: []
  use GenServer
  alias Pixie.Timeouts, as: Timeout

  @default_timeout 5

  def start_link do
    GenServer.start_link __MODULE__, initial_state, name: __MODULE__
  end

  def add(timeout_id, module, function, args) do
    add timeout_id, @default_timeout, module, function, args
  end

  def add timeout_id, timeout_ttl, module, function, args do
    GenServer.cast __MODULE__, {:add_timeout, timeout_id, timeout_ttl, module, function, args}
  end

  def remove timeout_id do
    GenServer.cast __MODULE__, {:remove_timeout, timeout_id}
  end

  def expire timeout_id do
    GenServer.cast __MODULE__, {:expire, timeout_id}
  end

  def handle_cast {:add_timeout, timeout_id, timeout_ttl, mod, fun, args}, state do
    timeout = Map.get state, timeout_id, %Timeout{}
    cancel timeout

    {:ok, tref} = :timer.apply_after timeout_ttl * 1000, __MODULE__, :expire, [timeout_id]
    timeout = %{timeout |
      timer_ref: tref,
      module:    mod,
      function:  fun,
      args:      args
    }
    state = Map.put state, timeout_id, timeout
    {:noreply, state}
  end

  def handle_cast {:remove_timeout, timeout_id}, state do
    timeout = Map.get state, timeout_id, %Timeout{}
    cancel timeout

    state = Map.delete state, timeout_id

    {:noreply, state}
  end

  def handle_cast {:expire, timeout_id}, state do
    if Map.has_key? state, timeout_id do
      %{module: mod, function: fun, args: args} = Map.get state, timeout_id
      Task.async mod, fun, args
    end

    state = Map.delete state, timeout_id
    {:noreply, state}
  end

  defp initial_state do
    %{}
  end

  defp cancel(%Timeout{timer_ref: tref}) when not is_nil(tref) do
    :timer.cancel(tref)
  end

  defp cancel(_), do: nil
end
