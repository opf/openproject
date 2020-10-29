# frozen_string_literal: true

require 'spec_helper'
require 'grape-entity'

describe Grape::Middleware::Error do
  module ErrorSpec
    class ErrorEntity < Grape::Entity
      expose :code
      expose :static

      def static
        'static text'
      end
    end

    class ErrApp
      class << self
        attr_accessor :error
        attr_accessor :format

        def call(_env)
          throw :error, error
        end
      end
    end
  end

  def app
    opts = options
    Rack::Builder.app do
      use Spec::Support::EndpointFaker
      use Grape::Middleware::Error, opts
      run ErrorSpec::ErrApp
    end
  end

  let(:options) { { default_message: 'Aww, hamburgers.' } }

  it 'sets the status code appropriately' do
    ErrorSpec::ErrApp.error = { status: 410 }
    get '/'
    expect(last_response.status).to eq(410)
  end

  it 'sets the error message appropriately' do
    ErrorSpec::ErrApp.error = { message: 'Awesome stuff.' }
    get '/'
    expect(last_response.body).to eq('Awesome stuff.')
  end

  it 'defaults to a 500 status' do
    ErrorSpec::ErrApp.error = {}
    get '/'
    expect(last_response.status).to eq(500)
  end

  it 'has a default message' do
    ErrorSpec::ErrApp.error = {}
    get '/'
    expect(last_response.body).to eq('Aww, hamburgers.')
  end

  context 'with http code' do
    let(:options) {  { default_message: 'Aww, hamburgers.' } }
    it 'adds the status code if wanted' do
      ErrorSpec::ErrApp.error = { message: { code: 200 } }
      get '/'

      expect(last_response.body).to eq({ code: 200 }.to_json)
    end

    it 'presents an error message' do
      ErrorSpec::ErrApp.error = { message: { code: 200, with: ErrorSpec::ErrorEntity } }
      get '/'

      expect(last_response.body).to eq({ code: 200, static: 'static text' }.to_json)
    end
  end
end
