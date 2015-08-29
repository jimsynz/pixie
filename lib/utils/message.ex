defmodule Pixie.Utils.Message do
  def get result, message, field do
    case Map.get message, field do
      nil -> result
      v   -> Map.put result, field, v
    end
  end

  def get result, message, field, default do
    case Map.get message, field do
      nil -> Map.put result, field, default
      v   -> Map.put result, field, v
    end
  end
end
