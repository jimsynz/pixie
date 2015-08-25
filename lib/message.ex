defmodule Pixie.Message do
  alias Pixie.Utils

  def init message do
    message
      |> Utils.atomize_keys
      |> Utils.underscore_keys
      |> do_init
  end

  defp do_init %{channel: "/meta/handshake"}=message do
    Pixie.Message.Handshake.init message
  end

end
