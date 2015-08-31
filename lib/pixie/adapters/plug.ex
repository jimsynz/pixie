defmodule Pixie.Adapter.Plug do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    IO.inspect conn
    send_resp conn, 200, "It worked!"
  end

  match _ do
    send_resp conn, 200, "oops"
  end
end
