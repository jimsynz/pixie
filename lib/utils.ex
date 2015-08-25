require Mix.Utils

defmodule Pixie.Utils do

  def camelize(term) when is_atom(term) do
    term |> Atom.to_string |> camelize |> String.to_atom
  end

  def camelize(term) when is_bitstring(term) do
    term |> Mix.Utils.camelize
  end

  def underscore(term) when is_atom(term) do
    term |> Atom.to_string |> underscore |> String.to_atom
  end

  def underscore(term) when is_bitstring(term) do
    term |> Mix.Utils.underscore
  end

  def camelize_keys map do
    Enum.reduce map, %{}, fn
      ({key, value}, acc) when is_atom(key) ->
        Map.put acc, camelize(key), value
      ({key, value}, acc) when is_bitstring(key)->
        Map.put acc, camelize(key), value
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
end
