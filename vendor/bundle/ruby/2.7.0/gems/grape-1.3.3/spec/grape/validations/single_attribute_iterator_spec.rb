# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::SingleAttributeIterator do
  describe '#each' do
    subject(:iterator) { described_class.new(validator, scope, params) }
    let(:scope) { Grape::Validations::ParamsScope.new(api: Class.new(Grape::API)) }
    let(:validator) { double(attrs: %i[first second]) }

    context 'when params is a hash' do
      let(:params) do
        { first: 'string', second: 'string' }
      end

      it 'yields params and every single attribute from the list' do
        expect { |b| iterator.each(&b) }
          .to yield_successive_args([params, :first, false], [params, :second, false])
      end
    end

    context 'when params is an array' do
      let(:params) do
        [{ first: 'string1', second: 'string1' }, { first: 'string2', second: 'string2' }]
      end

      it 'yields every single attribute from the list for each of the array elements' do
        expect { |b| iterator.each(&b) }.to yield_successive_args(
          [params[0], :first, false], [params[0], :second, false],
          [params[1], :first, false], [params[1], :second, false]
        )
      end

      context 'empty values' do
        let(:params) { [{}, '', 10] }

        it 'marks params with empty values' do
          expect { |b| iterator.each(&b) }.to yield_successive_args(
            [params[0], :first, true], [params[0], :second, true],
            [params[1], :first, true], [params[1], :second, true],
            [params[2], :first, false], [params[2], :second, false]
          )
        end
      end
    end
  end
end
