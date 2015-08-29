defmodule PixieBackendsProcessSpec do
  use ESpec
  alias Pixie.Backend.Process

  describe "init" do
    it "returns the initial state" do
      {:ok, %{namespaces: ns, options: opts}} = Process.init :foo
      expect(ns.__struct__).to eq(HashSet)
      expect(opts).to eq(:foo)
    end
  end

  describe "GenServer calls" do
    let :state, do: %{namespaces: HashSet.new, clients: HashSet.new}

    describe :generate_namespace do
      it "returns the correct length namespace" do
        {:reply, ns, _} = Process.handle_call {:generate_namespace, 27}, self, state
        expect(ns).to have_length(27)
      end

      it "stores the generated namespace in the state" do
        {:reply, ns, %{namespaces: used}} = Process.handle_call {:generate_namespace, 27}, self, state
        expect(used).to have(ns)
      end

      pending "generates only unique namespaces"
    end

    describe :release_namespace do
      it "removes the namespace from the state" do
        {:reply, ns, %{namespaces: used}=state} = Process.handle_call {:generate_namespace, 27}, self, state

        expect(used).to have(ns)
        {:noreply, %{namespaces: used}} = Process.handle_cast {:release_namespace, ns}, state
        expect(used).not_to have(ns)
      end
    end

    describe :create_client do
      it "generates a new client" do
        {:reply, client, _state} = Process.handle_call :create_client, self, state
        expect(client).not_to be_nil
      end
    end
  end
end
