defmodule Pixie.Utils.Message do
  def get handshake, message, field do
    case Map.get message, field do
      nil -> handshake
      v   -> Map.put handshake, field, v
    end
  end
end
