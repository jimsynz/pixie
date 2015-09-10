require Logger

defmodule Pixie.Protocol do

  def handle(messages) when is_list(messages) do
    messages
      |> Enum.map(&Pixie.Message.init/1)
      |> only_handshake
      |> Enum.map(&handle/1)
      |> via_transport
  end

  def handle message do
    response = Pixie.Response.init message
    dispatch %Pixie.Event{message: message, response: response}
  end

  def respond_immediately?(messages) when is_list(messages) do
    Enum.any? messages, &respond_immediately?/1
  end
  def respond_immediately?(%Pixie.Response.Handshake{}),    do: true
  def respond_immediately?(%Pixie.Response.Disconnect{}),   do: true
  def respond_immediately?(%Pixie.Response.Publish{}),      do: true
  def respond_immediately?(%Pixie.Response.Subscribe{}),    do: Pixie.subscribe_immediately?
  def respond_immediately?(%Pixie.Response.Unsubscribe{}),  do: Pixie.subscribe_immediately?
  def respond_immediately?(%{error: e}) when not is_nil(e), do: true
  def respond_immediately?(%Pixie.Message.Publish{}),       do: true
  def respond_immediately?(_),                              do: false

  defp dispatch %Pixie.Event{message: %Pixie.Message.Handshake{}}=event do
    Pixie.Handshake.handle event
  end

  defp dispatch %Pixie.Event{message: %Pixie.Message.Connect{}}=event do
    Pixie.Connect.handle event
  end

  defp dispatch %Pixie.Event{message: %Pixie.Message.Disconnect{}}=event do
    Pixie.Disconnect.handle event
  end

  defp dispatch %Pixie.Event{message: %Pixie.Message.Subscribe{}}=event do
    Pixie.Subscribe.handle event
  end

  defp dispatch %Pixie.Event{message: %Pixie.Message.Unsubscribe{}}=event do
    Pixie.Unsubscribe.handle event
  end

  defp dispatch %Pixie.Event{message: %Pixie.Message.Publish{}}=event do
    Pixie.Publish.handle event
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

  defp via_transport [] do
    []
  end

  defp via_transport events do
    responses = Enum.filter_map(events, fn %{response: r}-> r end, fn %{response: r}-> r end)
    case find_transport events do
      nil -> responses
      t   -> Pixie.Transport.connect t, responses
    end
  end

  defp find_transport events do
    Enum.find_value events, fn
      %{client_id: nil} ->
        nil
      %{client_id: client_id} ->
        case Pixie.Client.transport client_id do
          pid when is_pid(pid) -> pid
          _ -> nil
        end
    end
  end
end
