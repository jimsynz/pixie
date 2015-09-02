defmodule Profile do
  @moduledoc "Profiling helpers for mix tasks"

  def elapsed_ms(old_now) do
    :timer.now_diff(:erlang.now, old_now) |> trunc |> div(1000)
  end

  def run(work_fun) when is_function(work_fun) do
    start = :erlang.now
    work_fun.()
    elapsed = elapsed_ms(start)
    IO.puts "elapsed:\t#{elapsed} ms"
  end
end

defmodule Mix.Tasks.Pixie.Profile do
  use Mix.Task
  @shortdoc "Run Pixie server inside ExProf"
  import ExProf.Macro

  def run args do
    Profile.run fn->
      Task.async fn ->
        profile do
          Mix.Task.run "pixie.server", args
        end
      end
      :timer.sleep(10_000)
      IO.inspect Application.stop :pixie
    end
  end
end
