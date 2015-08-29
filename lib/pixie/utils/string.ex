require Mix.Utils

defmodule Pixie.Utils.String do

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
end
