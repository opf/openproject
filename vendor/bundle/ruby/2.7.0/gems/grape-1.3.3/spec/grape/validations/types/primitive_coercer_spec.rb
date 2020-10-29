# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::Types::PrimitiveCoercer do
  let(:strict) { false }

  subject { described_class.new(type, strict) }

  describe '#call' do
    context 'Boolean' do
      let(:type) { Grape::API::Boolean }

      [true, 'true', 1].each do |val|
        it "coerces '#{val}' to true" do
          expect(subject.call(val)).to eq(true)
        end
      end

      [false, 'false', 0].each do |val|
        it "coerces '#{val}' to false" do
          expect(subject.call(val)).to eq(false)
        end
      end

      it 'returns an error when the given value cannot be coerced' do
        expect(subject.call(123)).to be_instance_of(Grape::Validations::Types::InvalidValue)
      end

      it 'coerces an empty string to nil' do
        expect(subject.call('')).to be_nil
      end
    end

    context 'String' do
      let(:type) { String }

      it 'coerces to String' do
        expect(subject.call(10)).to eq('10')
      end
    end

    context 'BigDecimal' do
      let(:type) { BigDecimal }

      it 'coerces to BigDecimal' do
        expect(subject.call(5)).to eq(BigDecimal(5))
      end
    end

    context 'the strict mode' do
      let(:strict) { true }

      context 'Boolean' do
        let(:type) { Grape::API::Boolean }

        it 'returns an error when the given value is not Boolean' do
          expect(subject.call(1)).to be_instance_of(Grape::Validations::Types::InvalidValue)
        end

        it 'returns a value as it is when the given value is Boolean' do
          expect(subject.call(true)).to eq(true)
        end
      end

      context 'BigDecimal' do
        let(:type) { BigDecimal }

        it 'returns an error when the given value is not BigDecimal' do
          expect(subject.call(1)).to be_instance_of(Grape::Validations::Types::InvalidValue)
        end

        it 'returns a value as it is when the given value is BigDecimal' do
          expect(subject.call(BigDecimal(0))).to eq(BigDecimal(0))
        end
      end
    end
  end
end
