# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::AtLeastOneOfValidator do
  describe '#validate!' do
    subject(:validate) { post path, params }

    module ValidationsSpec
      module AtLeastOneOfValidatorSpec
        class API < Grape::API
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :beer, :wine, :grapefruit
            at_least_one_of :beer, :wine, :grapefruit
          end
          post do
          end

          params do
            optional :beer, :wine, :grapefruit, :other
            at_least_one_of :beer, :wine, :grapefruit
          end
          post 'mixed-params' do
          end

          params do
            optional :beer, :wine, :grapefruit
            at_least_one_of :beer, :wine, :grapefruit, message: 'you should choose something'
          end
          post '/custom-message' do
          end

          params do
            requires :item, type: Hash do
              optional :beer, :wine, :grapefruit
              at_least_one_of :beer, :wine, :grapefruit, message: 'fail'
            end
          end
          post '/nested-hash' do
          end

          params do
            requires :items, type: Array do
              optional :beer, :wine, :grapefruit
              at_least_one_of :beer, :wine, :grapefruit, message: 'fail'
            end
          end
          post '/nested-array' do
          end

          params do
            requires :items, type: Array do
              requires :nested_items, type: Array do
                optional :beer, :wine, :grapefruit
                at_least_one_of :beer, :wine, :grapefruit, message: 'fail'
              end
            end
          end
          post '/deeply-nested-array' do
          end
        end
      end
    end

    def app
      ValidationsSpec::AtLeastOneOfValidatorSpec::API
    end

    context 'when all restricted params are present' do
      let(:path) { '/' }
      let(:params) { { beer: true, wine: true, grapefruit: true } }

      it 'does not return a validation error' do
        validate
        expect(last_response.status).to eq 201
      end

      context 'mixed with other params' do
        let(:path) { '/mixed-params' }
        let(:params) { { beer: true, wine: true, grapefruit: true, other: true } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end
    end

    context 'when a subset of restricted params are present' do
      let(:path) { '/' }
      let(:params) { { beer: true, grapefruit: true } }

      it 'does not return a validation error' do
        validate
        expect(last_response.status).to eq 201
      end
    end

    context 'when none of the restricted params is selected' do
      let(:path) { '/' }
      let(:params) { { other: true } }

      it 'returns a validation error' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'beer,wine,grapefruit' => ['are missing, at least one parameter must be provided']
        )
      end

      context 'when custom message is specified' do
        let(:path) { '/custom-message' }

        it 'returns a validation error' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'beer,wine,grapefruit' => ['you should choose something']
          )
        end
      end
    end

    context 'when exactly one of the restricted params is selected' do
      let(:path) { '/' }
      let(:params) { { beer: true } }

      it 'does not return a validation error' do
        validate
        expect(last_response.status).to eq 201
      end
    end

    context 'when restricted params are nested inside hash' do
      let(:path) { '/nested-hash' }

      context 'when at least one of them is present' do
        let(:params) { { item: { beer: true, wine: true } } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when none of them are present' do
        let(:params) { { item: { other: true } } }

        it 'returns a validation error with full names of the params' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'item[beer],item[wine],item[grapefruit]' => ['fail']
          )
        end
      end
    end

    context 'when restricted params are nested inside array' do
      let(:path) { '/nested-array' }

      context 'when at least one of them is present' do
        let(:params) { { items: [{ beer: true, wine: true }, { grapefruit: true }] } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when none of them are present' do
        let(:params) { { items: [{ beer: true, other: true }, { other: true }] } }

        it 'returns a validation error with full names of the params' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'items[1][beer],items[1][wine],items[1][grapefruit]' => ['fail']
          )
        end
      end
    end

    context 'when restricted params are deeply nested' do
      let(:path) { '/deeply-nested-array' }

      context 'when at least one of them is present' do
        let(:params) { { items: [{ nested_items: [{ wine: true }] }] } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when none of them are present' do
        let(:params) { { items: [{ nested_items: [{ other: true }] }] } }

        it 'returns a validation error with full names of the params' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'items[0][nested_items][0][beer],items[0][nested_items][0][wine],items[0][nested_items][0][grapefruit]' => ['fail']
          )
        end
      end
    end
  end
end
