defmodule Pixie.Backend.Redis.ClientGC do
  import Pixie.Backend.Redis.Connection
  alias Timex.Time
  use GenServer

  def start_link do
    GenServer.start_link __MODULE__, []
  end

  def init [] do
    {:ok, nil, staggered_timeout}
  end

  def handle_info :timeout, nil do
    {:ok, expired} = query ["ZRANGEBYSCORE", key, "-inf", cutoff]
    Enum.each expired, fn(client_id) ->
      Pixie.Backend.destroy_client client_id, "Client expired"
    end
    {:noreply, nil, staggered_timeout}
  end

  defp key do
    cluster_namespace("clients")
  end

  defp cutoff do
    Time.now |> Time.sub(Time.from(Pixie.timeout * 2, :msecs)) |> Time.to_usecs
  end

  defp staggered_timeout do
    # Generate a random number between 50 and 70 seconds to help ensure
    # that multiple processes aren't trying to GC simultaneously.
    # I don't really think it's a big deal, but maybe in the future we should
    # use a lock here?
    :random.uniform(20_000) + 50_000
  end
end
