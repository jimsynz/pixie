defmodule PixieUtilsRandomIdSpec do
  use ESpec
  import Pixie.Utils.RandomId

  describe "generate" do
    context "When not given a length" do
      it "defaults to 32" do
        expect(generate).to have_length(32)
      end
    end

    context "When given a length" do
      it "returns an ID of the correct length" do
        expect(generate 27).to have_length(27)
      end
    end

    it "contains only alphanumeric characters" do
      expect(generate 4096).to match(~r/[a-zA-Z0-9]{4096}/)
    end
  end
end
