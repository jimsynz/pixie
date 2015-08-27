defmodule Pixie.Client do
  @valid_states ~w| unconnected connecting connected disconnected |a

  defstruct state:      :unconnected,
            id:         nil,
            channels:   HashSet.new,
            message_id: 0

  alias Pixie.Client
  alias Pixie.Client.State

  def init id do
    %Client{id: id}
  end

  def unconnected?(c),  do: State.unconnected?(c)
  def connecting?(c),   do: State.connecting?(c)
  def connected?(c),    do: State.connected?(c)
  def disconnected?(c), do: State.disconnected?(c)
  def connecting!(c),   do: State.connecting!(c)
  def connected!(c),    do: State.connected!(c)
  def disconnected!(c), do: State.disconnected!(c)
end
