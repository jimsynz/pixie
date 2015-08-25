defmodule Mix.Tasks.Pixie.Server do
  use Mix.Task

  @shortdoc "Starts a stand-alone pixie server"

  @moduledoc """
  Starts a stand-alone instance of Pixie.  Probably only good for development and testing.

  ## Command line options

  This task accepts the same command-line arguments as `app.start`. For additional
  information, refer to the documentation for `Mix.Tasks.App.Start`.

  For example, to run `pixie.server` without checking dependencies:

    mix pixie.server --no-deps-check

  """
  def run args do
    Application.put_env(:pixie, :start_cowboy, true)
    Mix.Task.run "app.start", args
    no_halt
  end

  defp no_halt do
    unless iex_running?(), do: :timer.sleep(:infinity)
  end

  defp iex_running? do
    Code.ensure_loaded(IEx) && IEx.started?
  end
end
