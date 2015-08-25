defmodule Pixie.Client do
  @valid_states Enum.map ~w| connecting connected disconnected |, &String.to_atom/1

  defstruct state:      :disconnected,
            id:         nil,
            channels:   HashSet.new,
            message_id: 0

  alias Pixie.Client

  def init do
    %Client{id: Pixie.Namespace.generate}
  end
end
