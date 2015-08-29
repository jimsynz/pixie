defmodule Pixie.Utils.Map do
  import Pixie.Utils.String

  def camelize_keys(m), do: camelize_keys(m, false)

  def camelize_keys map, upper_first do
    Enum.reduce map, %{}, fn
      ({key, value}, acc) when is_atom(key) ->
        Map.put acc, camelize(key, upper_first), value
      ({key, value}, acc) when is_bitstring(key)->
        Map.put acc, camelize(key, upper_first), value
      ({key, value}, acc) ->
        Map.put acc, key, value
    end
  end

  def underscore_keys map do
    Enum.reduce map, %{}, fn
      ({key, value}, acc) when is_atom(key) ->
        Map.put acc, underscore(key), value
      ({key, value}, acc) when is_bitstring(key) ->
        Map.put acc, underscore(key), value
      ({key, value}, acc) ->
        Map.put acc, key, value
    end
  end

  def atomize_keys map do
    Enum.reduce map, %{}, fn
      ({key, value}, acc) when is_bitstring(key) ->
        Map.put acc, String.to_atom(key), value
      ({key, value}, acc) ->
        Map.put acc, key, value
    end
  end

  def missing_key? acc, message, key do
    case Map.get message, key do
      nil ->
        [key | acc]
      value when is_bitstring(value) and byte_size(value) == 0 ->
        [key | acc]
      value when is_list(value) and length(value) == 0 ->
        [key | acc]
      value when is_map(value) and map_size(value) == 0 ->
        [key | acc]
      _ ->
        acc
    end
  end
end
