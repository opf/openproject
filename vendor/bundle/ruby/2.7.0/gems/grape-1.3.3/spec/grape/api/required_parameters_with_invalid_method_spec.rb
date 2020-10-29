# frozen_string_literal: true

require 'spec_helper'

describe Grape::Endpoint do
  subject { Class.new(Grape::API) }

  def app
    subject
  end

  before do
    subject.namespace do
      params do
        requires :id, desc: 'Identifier.'
      end
      get ':id' do
      end
    end
  end

  context 'post' do
    it '405' do
      post '/something'
      expect(last_response.status).to eq 405
    end
  end
end
