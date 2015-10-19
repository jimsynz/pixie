defmodule PixieSubscribeToPublishExtensionSpec do
  alias Pixie.SubscribeToPublishExtension, as: Extension
  use ESpec

  describe "incoming" do
    let :pre,  do: %{message: %{channel_name: "/foo"}, client_id: "abcd1234", response: %{}}
    let :post, do: Extension.incoming(pre)

    context "When the client is subscribed to the channel" do
      it "allows the message to be published" do
        allow(Pixie.Backend).to accept(:client_subscribed?, fn(_,_)-> true end)
        expect(post.response).not_to have_key(:error)
      end
    end

    context "When the client is not subscribed to the channel" do
      it "sets a publish failed response" do
        allow(Pixie.Backend).to accept(:client_subscribed?, fn(_,_)-> false end)
        expect(post.response.error).to start_with("407:/foo:Publish failed")
      end
    end
  end

  describe "outgoing" do
    it "returns the message" do
      expect(Extension.outgoing(:foo)).to eq(:foo)
    end
  end
end
