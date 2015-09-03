defmodule Pixie.Utils.Backend do
  require ExMinimatch

  def compile_channel_matcher channel_name do
    ExMinimatch.compile channel_name
  end

  def channel_matches? compiled_matcher, channel_name do
    ExMinimatch.match compiled_matcher, channel_name
  end
end
