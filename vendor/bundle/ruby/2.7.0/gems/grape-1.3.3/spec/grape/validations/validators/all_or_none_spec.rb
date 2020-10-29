# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::AllOrNoneOfValidator do
  describe '#validate!' do
    subject(:validate) { post path, params }

    module ValidationsSpec
      module AllOrNoneOfValidatorSpec
        class API < Grape::API
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :beer, :wine, type: Boolean
            all_or_none_of :beer, :wine
          end
          post do
          end

          params do
            optional :beer, :wine, :other, type: Boolean
            all_or_none_of :beer, :wine
          end
          post 'mixed-params' do
          end

          params do
            optional :beer, :wine, type: Boolean
            all_or_none_of :beer, :wine, message: 'choose all or none'
          end
          post '/custom-message' do
          end

          params do
            requires :item, type: Hash do
              optional :beer, :wine, type: Boolean
              all_or_none_of :beer, :wine
            end
          end
          post '/nested-hash' do
          end

          params do
            requires :items, type: Array do
              optional :beer, :wine, type: Boolean
              all_or_none_of :beer, :wine
            end
          end
          post '/nested-array' do
          end

          params do
            requires :items, type: Array do
              requires :nested_items, type: Array do
                optional :beer, :wine, type: Boolean
                all_or_none_of :beer, :wine
              end
            end
          end
          post '/deeply-nested-array' do
          end
        end
      end
    end

    def app
      ValidationsSpec::AllOrNoneOfValidatorSpec::API
    end

    context 'when all restricted params are present' do
      let(:path) { '/' }
      let(:params) { { beer: true, wine: true } }

      it 'does not return a validation error' do
        validate
        expect(last_response.status).to eq 201
      end

      context 'mixed with other params' do
        let(:path) { '/mixed-params' }
        let(:params) { { beer: true, wine: true, other: true } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end
    end

    context 'when a subset of restricted params are present' do
      let(:path) { '/' }
      let(:params) { { beer: true } }

      it 'returns a validation error' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'beer,wine' => ['provide all or none of parameters']
        )
      end
    end

    context 'when custom message is specified' do
      let(:path) { '/custom-message' }
      let(:params) { { beer: true } }

      it 'returns a validation error' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'beer,wine' => ['choose all or none']
        )
      end
    end

    context 'when no restricted params are present' do
      let(:path) { '/' }
      let(:params) { { somethingelse: true } }

      it 'does not return a validation error' do
        validate
        expect(last_response.status).to eq 201
      end
    end

    context 'when restricted params are nested inside required hash' do
      let(:path) { '/nested-hash' }
      let(:params) { { item: { beer: true } } }

      it 'returns a validation error with full names of the params' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'item[beer],item[wine]' => ['provide all or none of parameters']
        )
      end
    end

    context 'when mutually exclusive params are nested inside array' do
      let(:path) { '/nested-array' }
      let(:params) { { items: [{ beer: true, wine: true }, { wine: true }] } }

      it 'returns a validation error with full names of the params' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'items[1][beer],items[1][wine]' => ['provide all or none of parameters']
        )
      end
    end

    context 'when mutually exclusive params are deeply nested' do
      let(:path) { '/deeply-nested-array' }
      let(:params) { { items: [{ nested_items: [{ beer: true }] }] } }

      it 'returns a validation error with full names of the params' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'items[0][nested_items][0][beer],items[0][nested_items][0][wine]' => [
            'provide all or none of parameters'
          ]
        )
      end
    end
  end
end
