defmodule PixieResponseHandshakeSpec do
  use ESpec

  let :message do
    Pixie.Message.Handshake.init %{
      channel:   "/meta/handshake",
      id:        "efgh5678"
    }
  end

  let :response do
    Pixie.Response.Handshake.init message
  end

  it "returns a Pixie.Response.Handshake struct" do
    expect(response.__struct__).to eq(Pixie.Response.Handshake)
  end

  it "has correct id" do
    expect(response.id).to eq("efgh5678")
  end
end
