# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::MutualExclusionValidator do
  describe '#validate!' do
    subject(:validate) { post path, params }

    module ValidationsSpec
      module MutualExclusionValidatorSpec
        class API < Grape::API
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :beer
            optional :wine
            optional :grapefruit
            mutually_exclusive :beer, :wine, :grapefruit
          end
          post do
          end

          params do
            optional :beer
            optional :wine
            optional :grapefruit
            optional :other
            mutually_exclusive :beer, :wine, :grapefruit
          end
          post 'mixed-params' do
          end

          params do
            optional :beer
            optional :wine
            optional :grapefruit
            mutually_exclusive :beer, :wine, :grapefruit, message: 'you should not mix beer and wine'
          end
          post '/custom-message' do
          end

          params do
            requires :item, type: Hash do
              optional :beer
              optional :wine
              optional :grapefruit
              mutually_exclusive :beer, :wine, :grapefruit
            end
          end
          post '/nested-hash' do
          end

          params do
            optional :item, type: Hash do
              optional :beer
              optional :wine
              optional :grapefruit
              mutually_exclusive :beer, :wine, :grapefruit
            end
          end
          post '/nested-optional-hash' do
          end

          params do
            requires :items, type: Array do
              optional :beer
              optional :wine
              optional :grapefruit
              mutually_exclusive :beer, :wine, :grapefruit
            end
          end
          post '/nested-array' do
          end

          params do
            requires :items, type: Array do
              requires :nested_items, type: Array do
                optional :beer, :wine, :grapefruit, type: Boolean
                mutually_exclusive :beer, :wine, :grapefruit
              end
            end
          end
          post '/deeply-nested-array' do
          end
        end
      end
    end

    def app
      ValidationsSpec::MutualExclusionValidatorSpec::API
    end

    context 'when all mutually exclusive params are present' do
      let(:path) { '/' }
      let(:params) { { beer: true, wine: true, grapefruit: true } }

      it 'returns a validation error' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'beer,wine,grapefruit' => ['are mutually exclusive']
        )
      end

      context 'mixed with other params' do
        let(:path) { '/mixed-params' }
        let(:params) { { beer: true, wine: true, grapefruit: true, other: true } }

        it 'returns a validation error' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'beer,wine,grapefruit' => ['are mutually exclusive']
          )
        end
      end
    end

    context 'when a subset of mutually exclusive params are present' do
      let(:path) { '/' }
      let(:params) { { beer: true, grapefruit: true } }

      it 'returns a validation error' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'beer,grapefruit' => ['are mutually exclusive']
        )
      end
    end

    context 'when custom message is specified' do
      let(:path) { '/custom-message' }
      let(:params) { { beer: true, wine: true } }

      it 'returns a validation error' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'beer,wine' => ['you should not mix beer and wine']
        )
      end
    end

    context 'when no mutually exclusive params are present' do
      let(:path) { '/' }
      let(:params) { { beer: true, somethingelse: true } }

      it 'does not return a validation error' do
        validate
        expect(last_response.status).to eq 201
      end
    end

    context 'when mutually exclusive params are nested inside required hash' do
      let(:path) { '/nested-hash' }
      let(:params) { { item: { beer: true, wine: true } } }

      it 'returns a validation error with full names of the params' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'item[beer],item[wine]' => ['are mutually exclusive']
        )
      end
    end

    context 'when mutually exclusive params are nested inside optional hash' do
      let(:path) { '/nested-optional-hash' }

      context 'when params are passed' do
        let(:params) { { item: { beer: true, wine: true } } }

        it 'returns a validation error with full names of the params' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'item[beer],item[wine]' => ['are mutually exclusive']
          )
        end
      end

      context 'when params are empty' do
        let(:params) { {} }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end
    end

    context 'when mutually exclusive params are nested inside array' do
      let(:path) { '/nested-array' }
      let(:params) { { items: [{ beer: true, wine: true }, { wine: true, grapefruit: true }] } }

      it 'returns a validation error with full names of the params' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'items[0][beer],items[0][wine]' => ['are mutually exclusive'],
          'items[1][wine],items[1][grapefruit]' => ['are mutually exclusive']
        )
      end
    end

    context 'when mutually exclusive params are deeply nested' do
      let(:path) { '/deeply-nested-array' }
      let(:params) { { items: [{ nested_items: [{ beer: true, wine: true }] }] } }

      it 'returns a validation error with full names of the params' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'items[0][nested_items][0][beer],items[0][nested_items][0][wine]' => ['are mutually exclusive']
        )
      end
    end
  end
end
