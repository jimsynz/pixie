defmodule PixieMessageSpec do
  use ESpec

  context "massages incoming message" do
    it "underscores keys" do
      message = Pixie.Message.init(%{
        channel: "/meta/handshake",
        minimumVersion: "1.0"
      })
      expect(Map.has_key? message, :minimum_version).to be_true
    end

    it "atomises keys" do
      message = Pixie.Message.init(%{
        "channel" => "/meta/handshake",
      })
      expect(Map.has_key? message, :channel).to be_true
    end
  end

  context "dispatching" do
    context "when channel is /meta/handshake" do
      it "returns a Pixie.Message.Handshake" do
        message = Pixie.Message.init(%{
          "channel" => "/meta/handshake",
        })
        expect(message.__struct__).to eq(Pixie.Message.Handshake)
      end
    end
  end
end
