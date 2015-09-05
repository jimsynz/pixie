defmodule Pixie.Message do
  alias Pixie.Utils.Map, as: MapUtils

  @moduledoc """
  This module handles dispatch of incoming messages to their corresponding
  message structs.
  """

  @doc """
  Take `message` (the map output from JSON decoding) and apply the following
  transformations:

    - Convert all keys to lower case.
    - Convert all keys to atoms.

  Then dispatch to the correct message module, based on message type.
  """
  def init message do
    message
      |> MapUtils.underscore_keys
      |> MapUtils.atomize_keys
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

  defp do_init message do
    Pixie.Message.Publish.init message
  end
end
