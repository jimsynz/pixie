ESpec.start


defmodule PidWaiter do
  def wait pid do
    wait pid, Process.alive? pid
  end

  def wait pid, true do
    :timer.sleep 2
    wait pid, Process.alive? pid
  end

  def wait _pid, false do
    :ok
  end
end

ESpec.configure fn(config) ->
 config.before fn ->
   {:ok, []}
 end

 config.finally fn(shared) ->
  if Dict.has_key?(shared, :pid) do
    Process.unlink shared.pid
    Process.exit shared.pid, :shutdown
    PidWaiter.wait shared.pid
  end
 end

end
