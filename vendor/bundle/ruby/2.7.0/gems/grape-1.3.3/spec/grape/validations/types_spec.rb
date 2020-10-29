# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::Types do
  module TypesSpec
    class FooType
      def self.parse(_); end
    end

    class BarType
      def self.parse; end
    end
  end

  describe '::primitive?' do
    [
      Integer, Float, Numeric, BigDecimal,
      Grape::API::Boolean, String, Symbol,
      Date, DateTime, Time
    ].each do |type|
      it "recognizes #{type} as a primitive" do
        expect(described_class.primitive?(type)).to be_truthy
      end
    end

    it 'identifies unknown types' do
      expect(described_class.primitive?(Object)).to be_falsy
      expect(described_class.primitive?(TypesSpec::FooType)).to be_falsy
    end
  end

  describe '::structure?' do
    [
      Hash, Array, Set
    ].each do |type|
      it "recognizes #{type} as a structure" do
        expect(described_class.structure?(type)).to be_truthy
      end
    end
  end

  describe '::special?' do
    [
      JSON, Array[JSON], File, Rack::Multipart::UploadedFile
    ].each do |type|
      it "provides special handling for #{type.inspect}" do
        expect(described_class.special?(type)).to be_truthy
      end
    end
  end

  describe '::custom?' do
    it 'returns false if the type does not respond to :parse' do
      expect(described_class.custom?(Object)).to be_falsy
    end

    it 'returns true if the type responds to :parse with one argument' do
      expect(described_class.custom?(TypesSpec::FooType)).to be_truthy
    end

    it 'returns false if the type\'s #parse method takes other than one argument' do
      expect(described_class.custom?(TypesSpec::BarType)).to be_falsy
    end
  end

  describe '::build_coercer' do
    it 'has internal cache variables' do
      expect(described_class.instance_variable_get(:@__cache)).to be_a(Hash)
      expect(described_class.instance_variable_get(:@__cache_write_lock)).to be_a(Mutex)
    end

    it 'caches the result of the build_coercer method' do
      original_cache = described_class.instance_variable_get(:@__cache)
      described_class.instance_variable_set(:@__cache, {})

      a_coercer = described_class.build_coercer(Array[String])
      b_coercer = described_class.build_coercer(Array[String])

      expect(a_coercer.object_id).to eq(b_coercer.object_id)

      described_class.instance_variable_set(:@__cache, original_cache)
    end
  end
end
