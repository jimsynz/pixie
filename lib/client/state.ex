defmodule Pixie.Client.State do
  alias Pixie.Client

  def connecting?(%Client{state: :connecting}), do: true
  def connecting?(%Client{state: _}), do: false
  def connected?(%Client{state: :connected}), do: true
  def connected?(%Client{state: _}), do: false
  def disconnected?(%Client{state: :disconnected}), do: true
  def disconnected?(%Client{state: _}), do: false

  def connecting! %Client{state: :disconnected}=client do
    %{client | state: :disconnected}
  end

  def connecting! %Client{state: state} do
    raise "Can't transition from :#{state} to :connecting"
  end

  def connected! %Client{state: :connecting}=client do
    %{client | state: :connected}
  end

  def connected! %Client{state: state} do
    raise "Can't transition from :#{state} to :connected"
  end

  def disconnected! %Client{state: :connected}=client do
    %{client | state: :disconnected}
  end

  def disconnected! %Client{state: state} do
    raise "Can't transition from :#{state} to :disconnected"
  end
end
