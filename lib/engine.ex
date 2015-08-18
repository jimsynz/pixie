defprotocol Pixie.Engine do
  def create_client engine
  def destroy_client engine, client_id
  def ping engine, client_id
  def client_exists? engine, client_id
  def subscribe engine, client_id, channel
  def unsubscribe engine, client_id, channel
  def publish engine, message, channels
end
