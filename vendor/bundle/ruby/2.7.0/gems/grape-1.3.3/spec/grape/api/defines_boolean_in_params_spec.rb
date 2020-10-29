# frozen_string_literal: true

require 'spec_helper'

describe Grape::API::Instance do
  describe 'boolean constant' do
    module DefinesBooleanInstanceSpec
      class API < Grape::API
        params do
          requires :message, type: Boolean
        end
        post :echo do
          { class: params[:message].class.name, value: params[:message] }
        end
      end
    end

    def app
      DefinesBooleanInstanceSpec::API
    end

    let(:expected_body) do
      { class: 'TrueClass', value: true }.to_s
    end

    it 'sets Boolean as a type' do
      post '/echo?message=true'
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq expected_body
    end

    context 'Params endpoint type' do
      subject { DefinesBooleanInstanceSpec::API.new.router.map['POST'].first.options[:params]['message'][:type] }
      it 'params type is a boolean' do
        is_expected.to eq 'Grape::API::Boolean'
      end
    end
  end
end
