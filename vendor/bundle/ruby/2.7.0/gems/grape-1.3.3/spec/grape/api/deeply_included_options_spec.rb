# frozen_string_literal: true

require 'spec_helper'

module DeeplyIncludedOptionsSpec
  module Defaults
    extend ActiveSupport::Concern
    included do
      format :json
    end
  end

  module Admin
    module Defaults
      extend ActiveSupport::Concern
      include DeeplyIncludedOptionsSpec::Defaults
    end

    class Users < Grape::API
      include DeeplyIncludedOptionsSpec::Admin::Defaults

      resource :users do
        get do
          status 200
        end
      end
    end
  end

  class Main < Grape::API
    mount DeeplyIncludedOptionsSpec::Admin::Users
  end
end

describe Grape::API do
  subject { DeeplyIncludedOptionsSpec::Main }

  def app
    subject
  end

  it 'works for unspecified format' do
    get '/users'
    expect(last_response.status).to eql 200
    expect(last_response.content_type).to eql 'application/json'
  end

  it 'works for specified format' do
    get '/users.json'
    expect(last_response.status).to eql 200
    expect(last_response.content_type).to eql 'application/json'
  end

  it "doesn't work for format different than specified" do
    get '/users.txt'
    expect(last_response.status).to eql 404
  end
end
