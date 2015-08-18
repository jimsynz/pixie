defmodule Pixie.UniqueId do
  @id_length 32

  @alphabet ~w|
    a b c d e f g h i j k l m n o p q r s t u v w x y z
    A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
    0 1 2 3 4 5 6 7 8 9
  |

  def generate, do: generate @id_length

  def generate id_length do
    generate_random_string "", id_length
  end

  defp generate_random_string string, 0 do
    string
  end

  defp generate_random_string string, remaining do
    string = string <> generate_random_character
    generate_random_string string, remaining - 1
  end

  defp generate_random_character do
    alphabet = @alphabet
    pos = :crypto.rand_uniform(0, Enum.count(alphabet))
    Enum.at alphabet, pos
  end
end
