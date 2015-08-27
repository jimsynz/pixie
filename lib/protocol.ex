defmodule Pixie.Protocol do

  def handle(messages) when is_list(messages) do
    messages
      |> Enum.map(&Pixie.Message.init/1)
      |> only_handshake
      |> Enum.map(&handle/1)
  end

  def handle message do
    response = Pixie.Response.init message
    dispatch %Pixie.Event{message: message, response: response}
  end

  defp dispatch %Pixie.Event{message: %Pixie.Message.Handshake{}}=event do
    Pixie.Handshake.handle event
  end

  defp dispatch %Pixie.Event{message: %Pixie.Message.Connect{}}=event do
    Pixie.Connect.handle event
  end

  defp only_handshake [] do
    []
  end

  defp only_handshake messages do
    case Enum.find(messages, fn
      %Pixie.Message.Handshake{} -> true
      _any_other_message_type_   -> false
    end) do
      nil ->
        messages
      message ->
        [message]
    end
  end
end
