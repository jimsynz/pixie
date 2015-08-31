defmodule Pixie do
  use Application

  @default_timeout 25_000 # 25 seconds.
  # @default_transports ~w| long-polling cross-origin-long-polling callback-polling websocket eventsource |
  @default_transports ~w| long-polling cross-origin-long-polling callback-polling websocket |
  @bayeux_version "1.0"

  def start(_,_), do: start
  def start do
    Pixie.Supervisor.start_link
  end

  def version do
    {:ok, version} = :application.get_key :pixie, :vsn
    to_string version
  end

  def bayeux_version do
    @bayeux_version
  end

  def timeout do
    Application.get_env(:pixie, :timeout, @default_timeout)
  end

  def backend_options do
    Application.get_env(:pixie, :backend, [name: :ETS])
  end

  def subscribe_immediately? do
    Application.get_env(:pixie, :subscribe_immediately, false)
  end

  def publish %Pixie.Message.Publish{}=message do
    Pixie.Backend.publish message
  end

  def publish %{}=message do
    publish Pixie.Message.Publish.init(message)
  end

  def publish channel, %{}=data do
    publish %{channel: channel, data: data}
  end

  def configured_extensions do
    Application.get_env(:pixie, :extensions, [])
  end

  def enabled_transports do
    Enum.into Application.get_env(:pixie, :enabled_transports, @default_transports), HashSet.new
  end
end
