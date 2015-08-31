defmodule Pixie.Server.Plug do
  use Plug.Router

  if Mix.env == :dev do
    use Plug.Debugger
  end

  plug Plug.Logger
  plug :index
  plug :match
  plug :dispatch

  forward "/pixie", to: Pixie.Adapter.Plug
  forward "/",      to: Plug.Static,        at: "/", from: {:pixie, "priv"}, gzip: true

  # Rewrite requests for "/" to "/index.html"
  def index %{path_info: []}=conn, _ do
    %{conn | path_info: ["index.html"]}
  end
  def index(conn, _), do: conn
end
