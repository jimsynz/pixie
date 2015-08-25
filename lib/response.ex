defmodule Pixie.Response do
  def init %Pixie.Message.Handshake{}=message do
    Pixie.Response.Handshake.init message
  end

  def successful?(%{error: error}) when error == nil do
    true
  end

  def successful?(%{error: _}) do
    false
  end

  def successful?(_), do: true
end
