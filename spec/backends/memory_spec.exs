defmodule PixieBackendsMemorySpec do
  use ESpec
  alias Pixie.Backend.Memory

  describe "init" do
    it "returns the initial state" do
      {:ok, %{namespaces: ns, options: opts}} = Memory.init :foo
      expect(ns.__struct__).to eq(HashSet)
      expect(opts).to eq(:foo)
    end
  end

  describe "GenServer calls" do
    let :state, do: %{namespaces: HashSet.new, clients: HashSet.new}

    describe :generate_namespace do
      it "returns the correct length namespace" do
        {:reply, ns, _} = Memory.handle_call {:generate_namespace, 27}, self, state
        expect(ns).to have_length(27)
      end

      it "stores the generated namespace in the state" do
        {:reply, ns, %{namespaces: used}} = Memory.handle_call {:generate_namespace, 27}, self, state
        expect(used).to have(ns)
      end

      pending "generates only unique namespaces"
    end

    describe :release_namespace do
      it "removes the namespace from the state" do
        {:reply, ns, %{namespaces: used}=state} = Memory.handle_call {:generate_namespace, 27}, self, state

        expect(used).to have(ns)
        {:noreply, %{namespaces: used}} = Memory.handle_cast {:release_namespace, ns}, state
        expect(used).not_to have(ns)
      end
    end

    describe :create_client do
      it "generates a new client" do
        {:reply, client, _state} = Memory.handle_call :create_client, self, state
        expect(client.__struct__).to eq(Pixie.Client)
      end
    end
  end
end
