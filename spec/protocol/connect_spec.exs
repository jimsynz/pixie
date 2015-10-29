defmodule PixieConnectSpec do
  use ESpec

  describe "handle" do
    let :client_id do
      {id, _} = Pixie.Backend.create_client
      id
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

    let :valid_message, do: %{channel: "/meta/connect", connection_type: "long-polling", client_id: client_id}

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

    describe "When passed a message with no client_id" do
      let :message, do: %{valid_message | client_id: nil}

      it "sets a parameter missing response" do
        expect(response.error).to start_with("402:clientId:")
      end
    end

    describe "When passed a message with no channel" do
      let :message, do: %{valid_message | channel: nil}

      it "sets a parameter missing response" do
        expect(response.error).to start_with("402:channel:")
      end
    end

    describe "When passed a message with no connection_type" do
      let :message, do: %{valid_message | connection_type: nil}

      it "sets a parameter missing response" do
        expect(response.error).to start_with("402:connectionType:")
      end
    end

    describe "When passed a message with an invalid client_id" do
      let :message, do: %{valid_message | client_id: "abcd1234"}

      it "sets a client unknown response" do
        expect(response.error).to start_with("401:abcd1234")
      end
    end
  end
end
