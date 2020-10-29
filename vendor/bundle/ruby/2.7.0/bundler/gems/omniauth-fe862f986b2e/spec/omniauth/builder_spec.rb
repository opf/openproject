require 'helper'

describe OmniAuth::Builder do
  describe '#provider' do
    it 'translates a symbol to a constant' do
      expect(OmniAuth::Strategies).to receive(:const_get).with('MyStrategy').and_return(Class.new)
      OmniAuth::Builder.new(nil) do
        provider :my_strategy
      end
    end

    it 'accepts a class' do
      class ExampleClass; end

      expect do
        OmniAuth::Builder.new(nil) do
          provider ::ExampleClass
        end
      end.not_to raise_error
    end

    it "raises a helpful LoadError message if it can't find the class" do
      expect do
        OmniAuth::Builder.new(nil) do
          provider :lorax
        end
      end.to raise_error(LoadError, 'Could not find matching strategy for :lorax. You may need to install an additional gem (such as omniauth-lorax).')
    end
  end

  describe '#options' do
    it 'merges provided options in' do
      k = Class.new
      b = OmniAuth::Builder.new(nil)
      expect(b).to receive(:use).with(k, :foo => 'bar', :baz => 'tik')

      b.options :foo => 'bar'
      b.provider k, :baz => 'tik'
    end

    it 'adds an argument if no options are provided' do
      k = Class.new
      b = OmniAuth::Builder.new(nil)
      expect(b).to receive(:use).with(k, :foo => 'bar')

      b.options :foo => 'bar'
      b.provider k
    end
  end
end
