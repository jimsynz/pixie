defmodule PixieMessageConnectSpec do
  use ESpec

  let :message do
    Pixie.Message.Connect.init %{
      channel:         "/meta/connect",
      client_id:       "abcd1234",
      connection_type: "long-polling",
      ext:             "foo bar",
      id:              "efgh5678"
    }
  end

  it "returns a Pixie.Message.Connect struct" do
    expect(message.__struct__).to eq(Pixie.Message.Connect)
  end

  it "has correct channe" do
    expect(message.channel).to eq("/meta/connect")
  end

  it "has correct client_id" do
    expect(message.client_id).to eq("abcd1234")
  end

  it "has correct connection_type" do
    expect(message.connection_type).to eq("long-polling")
  end

  it "has correct ext" do
    expect(message.ext).to eq("foo bar")
  end

  it "has correct id" do
    expect(message.id).to eq("efgh5678")
  end
end
