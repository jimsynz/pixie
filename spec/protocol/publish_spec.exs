defmodule PixiePublishSpec do
  use ESpec

  describe "handle" do
    let :client_id do
      {id, _} = Pixie.Backend.create_client
      id
    end

    let :event do
      m = Pixie.Message.Publish.init message
      r = Pixie.Response.init m
      %Pixie.Event{message: m, response: r}
    end

    let :handled, do: Pixie.Publish.handle event

    let :response do
      %{response: response} = handled
      response
    end

    let :client do
      %{client: client} = handled
      client
    end

    let :valid_message, do: %{channel: "/foo", client_id: client_id, data: %{message: "I like turtles!"}}

    before do
      old_config = Pixie.backend_options
      Application.put_env :pixie, :backend, [name: :ETS]
      {:ok, pid} = Pixie.Backend.start_link :ETS, []
      {:ok, pid: pid, old_config: old_config}
    end

    finally do
      Application.put_env :pixie, :backend, shared.old_config
      Process.exit(shared.pid, :normal)
    end

    describe "When sent a messages with no channel" do
      let :message, do: %{valid_message | channel: nil}

      it "sets a parameter missing response" do
        expect(response.error).to start_with("402:channel:")
      end
    end

    describe "When sent a message with no data" do
      let :message, do: %{valid_message | data: nil}

      it "sets a parameter missing response" do
        expect(response.error).to start_with("402:data:")
      end
    end

    describe "When sent a message with no client_id" do
      let :client_id, do: nil
      let :message,   do: valid_message

      it "sets a parameter missing response" do
        expect(response.error).to start_with("402:clientId:")
      end
    end

    describe "When sent message with a valid clientId" do
      let :message, do: valid_message

      it "copies the clientId to the event" do
        expect(handled.client_id).to eq(message.client_id)
      end
    end

    describe "When sent message with an invalid clientId" do
      let :client_id, do: "abcd1234"
      let :message,   do: valid_message

      it "sets a client unknown response" do
        expect(response.error).to start_with("401:abcd1234:")
      end
    end

    describe "When sent a valid message" do
      let :message, do: valid_message

      it "pipes it through the extensions" do
        allow(Pixie.ExtensionRegistry).to accept(:incoming, fn(%{message: m}=e)-> %{e | message: %{m | data: %{message: "Turtles suck"}}} end)
        expect(handled.message.data.message).to eq("Turtles suck")
      end
    end
  end
end
