# frozen_string_literal: true

require 'spec_helper'

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  before do
    subject.namespace :api do
      get ':id(/:ext)' do
        [params[:id], params[:ext]].compact.join('/')
      end

      put ':id' do
        params[:id]
      end
    end
  end

  context 'get' do
    it 'responds without ext' do
      get '/api/foo'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'foo'
    end

    it 'responds with ext' do
      get '/api/foo/bar'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'foo/bar'
    end
  end

  context 'put' do
    it 'responds' do
      put '/api/foo'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'foo'
    end
  end
end
