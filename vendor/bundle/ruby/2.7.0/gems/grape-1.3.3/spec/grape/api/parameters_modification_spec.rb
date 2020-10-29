# frozen_string_literal: true

require 'spec_helper'

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  before do
    subject.namespace :test do
      params do
        optional :foo, default: +'-abcdef'
      end
      get do
        params[:foo].slice!(0)
        params[:foo]
      end
    end
  end

  context 'when route modifies param value' do
    it 'param default should not change' do
      get '/test'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'abcdef'

      get '/test'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'abcdef'

      get '/test?foo=-123456'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq '123456'

      get '/test'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'abcdef'
    end
  end
end
