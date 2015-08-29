defmodule Pixie.Utils.Response do
  def put response, message, field do
    case Map.get message, field do
      nil -> response
      v   -> Map.put response, field, v
    end
  end
end
