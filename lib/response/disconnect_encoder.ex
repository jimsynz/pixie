require Pixie.Response.Encoder

defimpl Poison.Encoder, for: Pixie.Response.Disconnect do
  import Pixie.Response.Encoder
  import Pixie.Utils.Map

  def encode %{}=response, _opts do
    response
      |> Map.from_struct
      |> make_successful
      |> filter_client_id
      |> filter_empty_keys
      |> camelize_keys
      |> Poison.encode!
  end

  defp filter_client_id response do
    case response.successful do
      false ->
        Map.delete response, :client_id
      _ ->
        response
    end
  end
end
