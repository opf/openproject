# frozen_string_literal: true

require 'spec_helper'

module Grape
  module Presenters
    module PresenterSpec
      class Dummy
        include Grape::DSL::InsideRoute

        attr_reader :env, :request, :new_settings

        def initialize
          @env = {}
          @header = {}
          @new_settings = { namespace_inheritable: {}, namespace_stackable: {} }
        end
      end
    end

    describe Presenter do
      describe 'represent' do
        let(:object_mock) do
          Object.new
        end

        it 'represent object' do
          expect(Presenter.represent(object_mock)).to eq object_mock
        end
      end

      subject { PresenterSpec::Dummy.new }

      describe 'present' do
        let(:hash_mock) do
          { key: :value }
        end

        describe 'instance' do
          before do
            subject.present hash_mock, with: Grape::Presenters::Presenter
          end
          it 'presents dummy hash' do
            expect(subject.body).to eq hash_mock
          end
        end

        describe 'multiple presenter' do
          let(:hash_mock1) do
            { key1: :value1 }
          end

          let(:hash_mock2) do
            { key2: :value2 }
          end

          describe 'instance' do
            before do
              subject.present hash_mock1, with: Grape::Presenters::Presenter
              subject.present hash_mock2, with: Grape::Presenters::Presenter
            end

            it 'presents both dummy presenter' do
              expect(subject.body[:key1]).to eq hash_mock1[:key1]
              expect(subject.body[:key2]).to eq hash_mock2[:key2]
            end
          end
        end
      end
    end
  end
end
