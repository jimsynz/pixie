Code.require_file "backend_examples.exs", __DIR__

defmodule PixieRedisBackendSpec do
  use ESpec

  before do: {:ok, backend: Pixie.Backend.Redis}

  it_behaves_like(PixieBackendExamples)
end
