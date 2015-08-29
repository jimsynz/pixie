require Pixie.Response.Encoder

defimpl Poison.Encoder, for: Pixie.Response.Publish do
  def encode %{}=response, _opts do
    Pixie.Response.Encoder.encode response
  end
end
