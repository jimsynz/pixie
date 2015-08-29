defmodule Pixie.Message do
  alias Pixie.Utils.Map, as: MapUtils

  def init message do
    message
      |> MapUtils.atomize_keys
      |> MapUtils.underscore_keys
      |> do_init
  end

  defp do_init %{channel: "/meta/handshake"}=message do
    Pixie.Message.Handshake.init message
  end

  defp do_init %{channel: "/meta/connect"}=message do
    Pixie.Message.Connect.init message
  end

  defp do_init %{channel: "/meta/disconnect"}=message do
    Pixie.Message.Disconnect.init message
  end

  defp do_init %{channel: "/meta/subscribe"}=message do
    Pixie.Message.Subscribe.init message
  end

  defp do_init %{channel: "/meta/unsubscribe"}=message do
    Pixie.Message.Unsubscribe.init message
  end
end
