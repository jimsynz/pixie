defmodule Pixie.Event do
  defstruct client: nil, message: nil, response: nil

  # Transports should respond immediately to handshakes, disconnects and
  # errors, otherwise they can be batched.

  def respond_immediately?(events) when is_list(events) do
    Enum.any? events, &respond_immediately?/1
  end

  def respond_immediately? %{response: %Pixie.Response.Handshake{}} do
    true
  end

  def respond_immediately? %{response: %Pixie.Response.Disconnect{}} do
    true
  end

  def respond_immediately? %{response: %Pixie.Response.Subscribe{}} do
    Pixie.subscribe_immediately
  end

  def respond_immediately? %{response: %Pixie.Response.Unsubscribe{}} do
    Pixie.subscribe_immediately
  end

  def respond_immediately?(%{response: %{error: e}}) when not is_nil(e) do
    true
  end

  def respond_immediately?(_), do: false
end
