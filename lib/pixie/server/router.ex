defmodule Pixie.Server.Router do
  use Plug.Builder

  if Mix.env == :dev do
    use Plug.Debugger
  end

  plug Plug.Logger
  plug :index
  plug Plug.Static, at: "/", from: {:pixie, "priv"}, gzip: true
  plug :not_found

  # Rewrite requests for "/" to "/index.html"
  def index %{path_info: []}=conn, _ do
    %{conn | path_info: ["index.html"]}
  end
  def index(conn, _), do: conn

  def not_found conn, _ do
    send_resp conn, 404, "Not found"
  end
end
