# frozen_string_literal: true

require 'spec_helper'

describe Grape::Validations::SameAsValidator do
  module ValidationsSpec
    module SameAsValidatorSpec
      class API < Grape::API
        params do
          requires :password
          requires :password_confirmation, same_as: :password
        end
        post do
        end

        params do
          requires :password
          requires :password_confirmation, same_as: { value: :password, message: 'not match' }
        end
        post '/custom-message' do
        end
      end
    end
  end

  def app
    ValidationsSpec::SameAsValidatorSpec::API
  end

  describe '/' do
    context 'is the same' do
      it do
        post '/', password: '987654', password_confirmation: '987654'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'is not the same' do
      it do
        post '/', password: '123456', password_confirmation: 'whatever'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('password_confirmation is not the same as password')
      end
    end
  end

  describe '/custom-message' do
    context 'is the same' do
      it do
        post '/custom-message', password: '987654', password_confirmation: '987654'
        expect(last_response.status).to eq(201)
        expect(last_response.body).to eq('')
      end
    end

    context 'is not the same' do
      it do
        post '/custom-message', password: '123456', password_confirmation: 'whatever'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('password_confirmation not match')
      end
    end
  end
end
