# frozen_string_literal: true

require 'spec_helper'
require 'base64'

describe Grape::Middleware::Auth::Base do
  subject do
    Class.new(Grape::API) do
      http_basic realm: 'my_realm' do |user, password|
        user && password && user == password
      end
      get '/authorized' do
        'DONE'
      end
    end
  end

  def app
    subject
  end

  it 'authenticates if given valid creds' do
    get '/authorized', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'admin')
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('DONE')
  end

  it 'throws a 401 is wrong auth is given' do
    get '/authorized', {}, 'HTTP_AUTHORIZATION' => encode_basic_auth('admin', 'wrong')
    expect(last_response.status).to eq(401)
  end
end
