defmodule Pixie.LoggingMonitor do
  use Pixie.Monitor
  require Logger

  def created_client client_id, _at do
    Logger.info "[#{client_id}]: Client created"
  end

  def destroyed_client client_id, _at do
    Logger.info "[#{client_id}]: Client destroyed."
  end

  def created_channel channel_name, _at do
    Logger.info "Channel created: #{inspect channel_name}."
  end

  def destroyed_channel channel_name, _at do
    Logger.info "Channel destroyed: #{inspect channel_name}."
  end

  def client_subscribed client_id, channel_name, _at do
    Logger.info "[#{client_id}]: Subscribed to #{channel_name}."
  end

  def client_unsubscribed client_id, channel_name, _at do
    Logger.info "[#{client_id}]: Unsubscribed to #{channel_name}."
  end

  def received_message client_id, message_id, _at do
    Logger.info "[#{client_id}]: Received message: #{inspect message_id}"
  end

  def delivered_message client_id, message_id, _at do
    Logger.info "[#{client_id}]: Delivered message: #{inspect message_id}"
  end
end
