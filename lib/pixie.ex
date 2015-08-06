defmodule Pixie do
  use Application

  def start(_,_), do: start
  def start do
    :erlfaye_cluster.start
  end

  def stop(_), do: stop
  def stop do
    :erlfaye_cluster.stop
  end

  def version do
    {:ok, version} = :application.get_key :pixie, :vsn
    to_string version
  end
end
