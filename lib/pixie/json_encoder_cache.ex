defmodule Pixie.JsonEncoderCache do
  def start_link do
    ConCache.start_link [
      ttl_check:     :timer.seconds(1),
      ttl:           :timer.seconds(15),
      touch_on_read: true
    ], name: __MODULE__
  end

  def encode!(terms) when is_list(terms) do
    Enum.map terms, fn(term)-> encode! term end
  end

  def encode! term do
    ConCache.get_or_store __MODULE__, term, fn()->
      Poison.encode! term
    end
  end
end
