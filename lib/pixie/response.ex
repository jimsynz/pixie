defmodule Pixie.Response do

  @moduledoc """
  This module handles creation of appropriate responses to client messages.
  """

  @doc """
  Based on the incoming message type, delegate to the correct Response module.
  """
  def init %Pixie.Message.Handshake{}=message do
    Pixie.Response.Handshake.init message
  end

  def init %Pixie.Message.Connect{}=message do
    Pixie.Response.Connect.init message
  end

  def init %Pixie.Message.Disconnect{}=message do
    Pixie.Response.Disconnect.init message
  end

  def init %Pixie.Message.Subscribe{}=message do
    Pixie.Response.Subscribe.init message
  end

  def init %Pixie.Message.Unsubscribe{}=message do
    Pixie.Response.Unsubscribe.init message
  end

  def init %Pixie.Message.Publish{}=message do
    Pixie.Response.Publish.init message
  end

  @doc """
  Report whether the response is "successful", ie whether the response contains
  a value in it's error field or not.
  """
  def successful?(%{error: nil}) do
    true
  end

  def successful?(%{error: _}) do
    false
  end

  def successful?(_), do: true
end
