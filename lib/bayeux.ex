defmodule Pixie.Bayeux do
  alias Pixie.Errors

  def process req, message do
    IO.inspect message
    Errors.not_acceptable req
  end
end
