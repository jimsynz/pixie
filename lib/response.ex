defmodule Pixie.Response do
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

  def successful?(%{error: error}) when error == nil do
    true
  end

  def successful?(%{error: _}) do
    false
  end

  def successful?(_), do: true
end
