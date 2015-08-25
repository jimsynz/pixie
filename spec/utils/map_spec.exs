defmodule PixieUtilsMapSpec do
  use ESpec
  import Pixie.Utils.Map

  describe "camelize_keys" do
    context "When called with no upper_first parameter" do
      it "defaults to lower first" do
        result = camelize_keys %{foo_bar: :baz}
        expect(result.fooBar).to eq(:baz)
      end
    end

    context "When called with upper first" do
      it "sets upper first keys" do
        result = camelize_keys %{foo_bar: :baz}, true
        expect(result[:FooBar]).to eq(:baz)
      end
    end

    context "When called with lower first" do
      it "sets lower first keys" do
        result = camelize_keys %{foo_bar: :baz}, false
        expect(result.fooBar).to eq(:baz)
      end
    end

    it "camelizes atom keys" do
      result = camelize_keys %{foo_bar: :baz}
      expect(result.fooBar).to eq(:baz)
    end

    it "camelizes string keys" do
      result = camelize_keys %{"foo_bar" => :baz}
      expect(result["fooBar"]).to eq(:baz)
    end

    it "passes through other terms" do
      result = camelize_keys %{13 => 27}
      expect(result[13]).to eq(27)
    end
  end

  describe "underscore_keys" do
    it "underscores atom keys" do
      result = underscore_keys %{:FooBar => :baz}
      expect(result.foo_bar).to eq(:baz)
    end

    it "underscores string keys" do
      result = underscore_keys %{"fooBar" => :baz}
      expect(result["foo_bar"]).to eq(:baz)
    end

    it "passes through other terms" do
      result = underscore_keys %{13 => 27}
      expect(result[13]).to eq(27)
    end
  end

  describe "atomize_keys" do
    it "converts string keys to atoms" do
      result = atomize_keys %{"foo_bar" => :baz}
      expect(result.foo_bar).to eq(:baz)
    end

    it "passes through other terms" do
      result = atomize_keys %{13 => 27}
      expect(result[13]).to eq(27)
    end
  end

  describe "missing_key?" do
    let :acc,  do: []
    let :hash, do: %{}
    let :key,  do: :foo
    subject do: missing_key?(acc, hash, key)

    context "when the key is missing" do
      it do: is_expected.to have(:foo)
    end

    context "when the key is present" do
      let :hash,  do: Map.put(%{}, key, value)

      context "and it has a value" do
        let :value, do: :baz

        it do: is_expected.not_to have(:foo)
      end

      context "and it is set to nil" do
        let :value, do: nil

        it do: is_expected.to have(:foo)
      end

      context "and it is an empty list" do
        let :value, do: []

        it do: is_expected.to have(:foo)
      end

      context "and it is an empty map" do
        let :value, do: %{}

        it do: is_expected.to have(:foo)
      end
    end
  end
end
