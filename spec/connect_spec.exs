defmodule PixieConnectSpec do
  use ESpec

  describe "handle" do
    let :client_id do
      %{id: c_id} = Pixie.Backend.create_client
      c_id
    end

    let :event do
      m = Pixie.Message.Connect.init message
      r = Pixie.Response.init m
      %Pixie.Event{message: m, response: r}
    end

    let :handled, do: Pixie.Connect.handle event

    let :response do
      %{response: response} = handled
      response
    end

    let :client do
      %{client: client} = handled
      client
    end

    finally do: Pixie.Backend.destroy_client client_id

    describe "When passed a message with no client_id" do
      let :message, do: %{channel: "/meta/connect", connection_type: "long-polling"}

      it "sets a parameter missing response" do
        expect(response.error).to start_with("402:clientId:")
      end
    end

    describe "When passed a message with no channel" do
      let :message, do: %{client_id: client_id, connection_type: "long-polling"}

      it "sets a parameter missing response" do
        expect(response.error).to start_with("402:channel:")
      end
    end

    describe "When passed a message with no connection_type" do
      let :message, do: %{client_id: client_id, channel: "/meta/connect"}

      it "sets a parameter missing response" do
        expect(response.error).to start_with("402:connectionType:")
      end
    end

    describe "When passed a message with an invalid client_id" do
      let :message, do: %{client_id: "abcd1234"}

      it "sets a client unknown response" do
        expect(response.error).to start_with("401:abcd1234")
      end
    end
  end
end
