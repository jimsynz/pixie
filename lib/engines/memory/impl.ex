defimpl Pixie.Engine, for: Pixie.Engines.Memory do
  alias Pixie.Engines.Memory
  alias Pixie.Namespace

  def create_client %Memory{pid: pid} do
    GenServer.call pid, :create_client
  end

  def ping %Memory{pid: pid}=engine, client_id do
    GenServer.call pid, {:ping, engine, client_id}
  end

  def destroy_client %Memory{pid: pid}, client_id do
    GenServer.call pid, {:destroy_client, client_id}
  end

  def client_exists? %Memory{}, client_id do
    Namespace.exists? client_id
  end

  def subscribe %Memory{pid: pid}, client_id, channel do
    GenServer.call pid, {:subscribe, client_id, channel}
  end

  def unsubscribe %Memory{pid: pid}, client_id, channel do
    GenServer.call pid, {:unsubscribe, client_id, channel}
  end

  def publish %Memory{pid: pid}, message, channels do
    GenServer.cast pid, {:publish, message, channels}
  end
end
