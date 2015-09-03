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

 config.finally fn(__) ->
  if Dict.has_key?(__, :pid) do
    Process.unlink __.pid
    Process.exit __.pid, :shutdown
    PidWaiter.wait __.pid
  end
 end

end
