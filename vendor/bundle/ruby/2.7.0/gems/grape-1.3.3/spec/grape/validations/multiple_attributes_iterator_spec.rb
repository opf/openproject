# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::MultipleAttributesIterator do
  describe '#each' do
    subject(:iterator) { described_class.new(validator, scope, params) }
    let(:scope) { Grape::Validations::ParamsScope.new(api: Class.new(Grape::API)) }
    let(:validator) { double(attrs: %i[first second third]) }

    context 'when params is a hash' do
      let(:params) do
        { first: 'string', second: 'string' }
      end

      it 'yields the whole params hash without the list of attrs' do
        expect { |b| iterator.each(&b) }.to yield_with_args(params)
      end
    end

    context 'when params is an array' do
      let(:params) do
        [{ first: 'string1', second: 'string1' }, { first: 'string2', second: 'string2' }]
      end

      it 'yields each element of the array without the list of attrs' do
        expect { |b| iterator.each(&b) }.to yield_successive_args(params[0], params[1])
      end
    end
  end
end
