# frozen_string_literal: true

require 'spec_helper'

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  before do
    subject.namespace do
      format :json
      content_type :json, 'application/json'
      params do
        requires :id, desc: 'Identifier.'
      end
      get ':id' do
        {
          id: params[:id],
          format: params[:format]
        }
      end
    end
  end

  context 'get' do
    it 'no format' do
      get '/foo'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq(::Grape::Json.dump(id: 'foo', format: nil))
    end
    it 'json format' do
      get '/foo.json'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq(::Grape::Json.dump(id: 'foo', format: 'json'))
    end
    it 'invalid format' do
      get '/foo.invalid'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq(::Grape::Json.dump(id: 'foo', format: 'invalid'))
    end
  end
end
