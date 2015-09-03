Code.require_file "backend_examples.exs", __DIR__

defmodule PixieEtsBackendSpec do
  use ESpec

  before do: {:ok, backend: Pixie.Backend.ETS}

  it_behaves_like(PixieBackendExamples)
end
