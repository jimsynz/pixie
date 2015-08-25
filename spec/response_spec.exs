defmodule PixieResponseSpec do
  use ESpec

  describe "init" do
    let :response, do: Pixie.Response.init message

    context "When passed a handshake message" do
      let :message,  do: Pixie.Message.Handshake.init %{}

      it "returns a Handshake response" do
        expect(response.__struct__).to eq(Pixie.Response.Handshake)
      end
    end
  end

  describe "successful?" do
    subject do: Pixie.Response.successful? response

    context "When passed a response with error set" do
      let :response, do: %{error: "Uploading virus"}

      it do: is_expected.to be_false
    end

    context "When passed a response with an error key, but not set" do
      let :response, do: %{error: nil}

      it do: is_expected.to be_true
    end

    context "When passed a response with no error key" do
      let :response, do: %{}

      it do: is_expected.to be_true
    end
  end
end
