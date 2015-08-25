require Mix.Utils

defmodule Pixie.Utils do

  def camelize(term), do: camelize(term, false)

  def camelize(term, upper_first) when is_atom(term) do
    term |> Atom.to_string |> camelize(upper_first) |> String.to_atom
  end

  def camelize(term, upper_first) when is_bitstring(term) and upper_first == true do
    term |> Mix.Utils.camelize
  end

  def camelize(term, upper_first) when is_bitstring(term) and upper_first == false do
    {first, rest} = term |> camelize(true) |> String.split_at(1)
    "#{String.downcase first}#{rest}"
  end

  def underscore(term) when is_atom(term) do
    term |> Atom.to_string |> underscore |> String.to_atom
  end

  def underscore(term) when is_bitstring(term) do
    term |> Mix.Utils.underscore
  end

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
