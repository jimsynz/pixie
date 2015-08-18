defprotocol Pixie.Server do
  def timeout server
  def debug server, message
  def deliver server, client_id, message
  def handshake server, client_id
  def disconnect server, client_id
  def close server, client_id
  def subscribe server, client_id, channel
  def unsubscribe server, client_id, channel
end
