# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::Types::ArrayCoercer do
  subject { described_class.new(type) }

  describe '#call' do
    context 'an array of primitives' do
      let(:type) { Array[String] }

      it 'coerces elements in the array' do
        expect(subject.call([10, 20])).to eq(%w[10 20])
      end
    end

    context 'an array of arrays' do
      let(:type) { Array[Array[Integer]] }

      it 'coerces elements in the nested array' do
        expect(subject.call([%w[10 20]])).to eq([[10, 20]])
        expect(subject.call([['10'], ['20']])).to eq([[10], [20]])
      end
    end

    context 'an array of sets' do
      let(:type) { Array[Set[Integer]] }

      it 'coerces elements in the nested set' do
        expect(subject.call([%w[10 20]])).to eq([Set[10, 20]])
        expect(subject.call([['10'], ['20']])).to eq([Set[10], Set[20]])
      end
    end
  end
end
