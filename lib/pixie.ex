defmodule Pixie do
  use Application

  @default_timeout 25_000 # 25 seconds.

  def start(_,_), do: start
  def start do
    Pixie.Supervisor.start_link
  end

  def version do
    {:ok, version} = :application.get_key :pixie, :vsn
    to_string version
  end

  def timeout do
    Application.get_env(:pixie, :timeout, @default_timeout)
  end

  def backend_options do
    Application.get_env(:pixie, :backend, [name: :Process])
  end
end
