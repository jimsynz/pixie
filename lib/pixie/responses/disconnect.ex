defmodule Pixie.Response.Disconnect do
  defstruct channel: "/meta/disconnect", client_id: nil, error: nil, ext: nil, id: nil
  import Pixie.Utils.Response

  def init %Pixie.Message.Disconnect{}=message do
    %Pixie.Response.Disconnect{}
      |> put(message, :id)
      |> put(message, :client_id)
  end
end
