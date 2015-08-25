defmodule PixieResponseConnectSpec do
  use ESpec

  let :message do
    Pixie.Message.Connect.init %{
      channel:   "/meta/connect",
      client_id: "abcd1234",
      id:        "efgh5678"
    }
  end

  let :response do
    Pixie.Response.Connect.init message
  end

  it "returns a Pixie.Response.Connect struct" do
    expect(response.__struct__).to eq(Pixie.Response.Connect)
  end

  it "has correct client_id" do
    expect(response.client_id).to eq("abcd1234")
  end

  it "has correct id" do
    expect(response.id).to eq("efgh5678")
  end
end
