# frozen_string_literal: true

require 'spec_helper'

describe Grape::API do
  let(:jobs_api) do
    Class.new(Grape::API) do
      namespace :one do
        namespace :two do
          namespace :three do
            get :one do
            end
            get :two do
            end
          end
        end
      end
    end
  end

  let(:combined_api) do
    JobsApi = jobs_api
    Class.new(Grape::API) do
      version :v1, using: :accept_version_header, cascade: true
      mount JobsApi
    end
  end

  subject do
    CombinedApi = combined_api
    Class.new(Grape::API) do
      format :json
      mount CombinedApi => '/'
    end
  end

  def app
    subject
  end

  it 'execute first request in reasonable time' do
    started = Time.now
    get '/mount1/nested/test_method'
    expect(Time.now - started).to be < 5
  end
end
