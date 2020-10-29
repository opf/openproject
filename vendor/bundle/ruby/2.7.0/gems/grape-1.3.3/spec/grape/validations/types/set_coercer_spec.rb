# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::Types::SetCoercer do
  subject { described_class.new(type) }

  describe '#call' do
    context 'a set of primitives' do
      let(:type) { Set[String] }

      it 'coerces elements to the set' do
        expect(subject.call([10, 20])).to eq(Set['10', '20'])
      end
    end

    context 'a set of sets' do
      let(:type) { Set[Set[Integer]] }

      it 'coerces elements in the nested set' do
        expect(subject.call([%w[10 20]])).to eq(Set[Set[10, 20]])
        expect(subject.call([['10'], ['20']])).to eq(Set[Set[10], Set[20]])
      end
    end

    context 'a set of sets of arrays' do
      let(:type) { Set[Set[Array[Integer]]] }

      it 'coerces elements in the nested set' do
        expect(subject.call([[['10'], ['20']]])).to eq(Set[Set[Array[10], Array[20]]])
      end
    end
  end
end
