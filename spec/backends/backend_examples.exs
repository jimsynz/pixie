defmodule PixieBackendExamples do
  use ESpec, shared: true

  let :backend, do: shared.backend

  before do
    config = Application.get_env(:pixie, :backend)
    new_config = [
      name: Module.split(shared.backend) |> List.last
    ]
    Application.put_env(:pixie, :backend, new_config)
    {:ok, pid} = apply(shared.backend, :start_link, [[]])
    {:ok, pid: pid, old_config: config}
  end

  finally do
    Process.exit shared.pid, :normal
    Application.put_env(:pixie, :backend, shared.old_config)
  end

  describe "start_link" do
    it "starts a new process" do
      expect(shared.pid).to be_pid
    end

    it "registers itself as a named process" do
      expect(Process.registered).to have(backend)
    end
  end

  describe "generate_namespace" do
    it "generates a random ID" do
      id = apply(backend, :generate_namespace, [32])
      expect(id).to be_binary
      expect(id).to have_length(32)
    end

    specify "no two are alike" do
      # We can't really test this, but we can generate a sample
      # and assert that there are no dupes.
      ids = Enum.map 0..999, fn(_) -> apply(backend, :generate_namespace, [32]) end

      expect(ids).to have_size(1000)
      expect(Enum.uniq(ids)).to have_size(1000)
    end
  end

  describe "release_namespace" do
    pending "not sure how to test this properly..."
  end

  describe "create_client" do
    it "creates a client" do
      {client_id, pid} = apply(backend, :create_client, [])
      expect(client_id).to be_binary
      expect(client_id).to have_length(32)
      expect(pid).to be_pid
    end
  end

  context "with client process" do
    before do
      {client_id, pid} = apply(backend, :create_client, [])
      {:ok, client_id: client_id, client_pid: pid}
    end

    let :client_id,  do: shared.client_id
    let :client_pid, do: shared.client_pid

    describe "get_client" do

      it "returns a previously created client process, by client_id" do
        pid = apply(backend, :get_client, [client_id])
        expect(client_pid).to eq(pid)
      end
    end

    describe "destroy_client" do

      it "destroys a client process, by client_id" do
        apply(backend, :destroy_client, [client_id])
        expect(Process.alive?(client_pid)).to be_false
        expect(apply(backend, :get_client, [client_id])).to be_nil
      end
    end

    describe "subscribe" do

      it "subscribes a client to a channel" do
        apply(backend, :subscribe, [client_id, "/foo"])
        # FIXME
        # using a delay here is awful, but `subscribe` is async, so I'm not
        # exactly sure how to do it, unless I make it sync and have the backend
        # return a task instead.
        :timer.sleep 10
        expect(apply(backend, :subscribers_of, ["/foo"])).to have(client_id)
        expect(apply(backend, :subscribed_to, [client_id])).to have("/foo")
        expect(apply(backend, :client_subscribed?, [client_id, "/foo"])).to be_true
      end
    end

    describe "unsubscribe" do

      it "unsubscribes the client from the channel" do
        apply(backend, :subscribe, [client_id, "/foo"])
        apply(backend, :unsubscribe, [client_id, "/foo"])
        expect(apply(backend, :subscribers_of, ["/foo"])).not_to have(client_id)
        expect(apply(backend, :subscribed_to, [client_id])).not_to have("/foo")
        expect(apply(backend, :client_subscribed?, [client_id, "/foo"])).not_to be_true
      end
    end

    describe "queue_for & dequeue_for" do
      it "stores and retrieves messages for a client" do
        messages = Enum.map 0..99, fn(i)-> %{n: i} end
        apply(backend, :queue_for, [client_id, messages])
        expect(apply(backend, :dequeue_for, [client_id])).to eq(messages)
      end
    end

  end
end
