defimpl Poison.Encoder, for: Pixie.Message.Publish do
  def encode message, _ do
    message
      |> Map.from_struct
      |> Map.take(~w| channel data id |a)
      |> Poison.encode!
  end
end
