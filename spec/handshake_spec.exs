defmodule PixieHandshakeSpec do
  use ESpec

  describe "handle" do
    let :event do
      m = Pixie.Message.Handshake.init message
      r = Pixie.Response.init m
      %Pixie.Event{message: m, response: r}
    end

    let :handled, do: Pixie.Handshake.handle event

    let :response do
      %{response: response} = handled
      response
    end

    let :client do
      %{client: client} = handled
      client
    end

    context "When passed a message with an incorrect version" do
      let :message, do: %{version: "42"}

      it "sets a version mismatch response" do
        expect(response.error).to start_with("300:")
      end

      it "does not create a new client" do
        expect(client).to be_nil
      end
    end

    context "When passed a message with missing parameters" do
      let :message, do: %{}

      it "sets a parameter missing response" do
        expect(response.error).to start_with("402:channel,supportedConnectionTypes,version:")
      end

      it "does not create a new client" do
        expect(client).to be_nil
      end
    end

    context "When passed a message with non matching connection types" do
      let :message, do: %{supported_connection_types: ~w| a b c d |, version: "1.0", channel: "/meta/handshake"}

      it "sets a connection type mismatch response" do
        expect(response.error).to start_with("301:")
      end

      it "does not create a new client" do
        expect(client).to be_nil
      end
    end

    context "When passed a valid handshake" do
      let :message, do: %{supported_connection_types: ~w| long-polling |, version: "1.0", channel: "/meta/handshake"}

      it "sets a successful response" do
        expect(Pixie.Response.successful? response).to be_true
      end

      it "creates a new client" do
        expect(client).not_to be_nil
      end
    end
  end
end
