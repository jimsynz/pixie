defmodule PixieMessageHandshakeSpec do
  use ESpec

  let :message do
    Pixie.Message.Handshake.init %{
      channel:                    "/meta/handshake",
      supported_connection_types: [],
      minimum_version:            "1.0",
      ext:                        "foo bar",
      id:                         "abcd1234"
    }
  end

  it "returns a Pixie.Message.Handshake struct" do
    expect(message.__struct__).to eq(Pixie.Message.Handshake)
  end

  it "has correct channel" do
    expect(message.channel).to eq "/meta/handshake"
  end

  it "has supported connection types" do
    transports = message.supported_connection_types
    expect(transports.__struct__).to eq(HashSet)
  end

  it "has minimum version" do
    expect(message.minimum_version).to eq("1.0")
  end

  it "has ext" do
    expect(message.ext).to eq("foo bar")
  end

  it "has id" do
    expect(message.id).to eq("abcd1234")
  end
end
