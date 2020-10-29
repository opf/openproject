# frozen_string_literal: true

require 'spec_helper'

module Grape
  module DSL
    module ValidationsSpec
      class Dummy
        include Grape::DSL::Validations
      end
    end

    describe Validations do
      subject { ValidationsSpec::Dummy }

      describe '.reset_validations!' do
        before do
          subject.namespace_stackable :declared_params, ['dummy']
          subject.namespace_stackable :validations, ['dummy']
          subject.namespace_stackable :params, ['dummy']
          subject.route_setting :description, description: 'lol', params: ['dummy']
          subject.reset_validations!
        end

        after do
          subject.unset_route_setting :description
        end

        it 'resets declared params' do
          expect(subject.namespace_stackable(:declared_params)).to eq []
        end

        it 'resets validations' do
          expect(subject.namespace_stackable(:validations)).to eq []
        end

        it 'resets params' do
          expect(subject.namespace_stackable(:params)).to eq []
        end

        it 'resets documentation params' do
          expect(subject.route_setting(:description)[:params]).to be_nil
        end

        it 'does not reset documentation description' do
          expect(subject.route_setting(:description)[:description]).to eq 'lol'
        end
      end

      describe '.params' do
        it 'returns a ParamsScope' do
          expect(subject.params).to be_a Grape::Validations::ParamsScope
        end

        it 'evaluates block' do
          expect { subject.params { raise 'foo' } }.to raise_error RuntimeError, 'foo'
        end
      end

      describe '.document_attribute' do
        before do
          subject.document_attribute([full_name: 'xxx'], foo: 'bar')
        end

        it 'creates a param documentation' do
          expect(subject.namespace_stackable(:params)).to eq(['xxx' => { foo: 'bar' }])
          expect(subject.route_setting(:description)).to eq(params: { 'xxx' => { foo: 'bar' } })
        end
      end
    end
  end
end
