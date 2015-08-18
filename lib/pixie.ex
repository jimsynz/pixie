defmodule Pixie do
  use Application

  def start(_,_), do: start
  def start do
    Pixie.Supervisor.start_link
  end

  def version do
    {:ok, version} = :application.get_key :pixie, :vsn
    to_string version
  end
end
