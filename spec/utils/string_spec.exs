defmodule PixieUtilsStringSpec do
  use ESpec
  import Pixie.Utils.String

  describe "camelize" do
    it "defaults to lower first" do
      expect(camelize "foo_bar").to eq("fooBar")
    end

    it "camelizes atoms" do
      expect(camelize :foo_bar).to eq(:fooBar)
    end

    it "camelizes strings" do
      expect(camelize "foo_bar").to eq("fooBar")
    end

    it "can camelize upper first" do
      expect(camelize "foo_bar", true).to eq("FooBar")
    end

    it "can camelize lower first" do
      expect(camelize "foo_bar", false).to eq("fooBar")
    end
  end

  describe "underscore" do
    it "can underscore atoms" do
      expect(underscore :FooBar).to eq(:foo_bar)
    end

    it "can underscore strings" do
      expect(underscore "fooBar").to eq("foo_bar")
    end
  end
end
