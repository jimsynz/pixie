defmodule PixieUtilsBackendSpec do
  use ESpec
  import Pixie.Utils.Backend

  describe "compiled_channel_matched" do
    it "delegates to ExMinimatch" do
      allow(ExMinimatch).to accept(:compile, fn(n) -> String.upcase(n) end)
      expect(compile_channel_matcher "foo").to eq("FOO")
    end
  end

  describe "channel_matches?" do
    it "validates whether a channel pattern matches another" do
      cn = compile_channel_matcher "/foo/*"
      expect(channel_matches?(cn, "/foo/bar")).to be_true
      expect(channel_matches?(cn, "/bar")).to be_false
    end
  end
end
