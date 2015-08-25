defmodule Pixie.Response.Utils do
  def put handshake, message, field do
    case Map.get message, field do
      nil -> handshake
      v   -> Map.put handshake, field, v
    end
  end
end
