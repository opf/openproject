# frozen_string_literal: true

require 'spec_helper'

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  before do
    subject.namespace :me do
      namespace :pending do
        get '/' do
          'banana'
        end
      end
      put ':id' do
        params[:id]
      end
    end
  end

  context 'get' do
    it 'responds without ext' do
      get '/me/pending'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'banana'
    end
  end

  context 'put' do
    it 'responds' do
      put '/me/foo'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'foo'
    end
  end
end
