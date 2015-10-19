defmodule Pixie.SubscribeToPublishExtension do
  use Pixie.Extension

  @moduledoc """
  Use this extension if you wish to ensure that only subscribed clients can
  publish to channels.
  """

  def incoming %{message: %{channel_name: channel_name}, client_id: client_id, response: r}=event do
    if Pixie.Backend.client_subscribed? client_id, channel_name do
      event
    else
      %{event | response: Error.publish_failed(r, channel_name)}
    end
  end

  def outgoing(event), do: event
end
