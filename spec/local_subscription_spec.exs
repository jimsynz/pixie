defmodule PixieLocalSubscriptionSpec do
  use ESpec
  require Faker

  before do
    {:ok, pid} = Pixie.Backend.start_link :ETS, []
    {:ok, pid: pid}
  end

  finally do
    Process.exit shared.pid, :normal
  end

  describe "subscribe" do
    context "when subscribing to a channel" do
      let :channel_name, do: fake_channel_name
      let :callback, do: empty_callback

      subject do: Pixie.LocalSubscription.subscribe(channel_name, callback)

      it "returns a pid" do
        {:ok, pid} = subject
        expect pid |> to(be_pid)
      end
    end
  end

  def fake_channel_name do
    words = Faker.Lorem.words 3
    words = [ "" | words ]
    Enum.join words, "/"
  end

  def empty_callback do
    fn (_,_) -> nil end
  end
end