defmodule Pixie.Server.Plug do
  use Plug.Router
  alias Pixie.Adapter.HttpError, as: Error

  if Mix.env == :dev do
    use Plug.Debugger
    plug Plug.Logger
  end

  plug :index
  plug :match
  plug :dispatch
  plug :not_found

  forward "/pixie", to: Pixie.Adapter.Plug
  forward "/",      to: Plug.Static,        at: "/", from: {:pixie, "priv"}, gzip: true

  def not_found conn, _ do
    Error.not_found conn
  end

  # Rewrite requests for "/" to "/index.html"
  def index %{path_info: []}=conn, _ do
    %{conn | path_info: ["index.html"]}
  end
  def index(conn, _), do: conn
end
