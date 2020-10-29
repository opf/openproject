# frozen_string_literal: true

require 'spec_helper'

describe Rack::Sendfile do
  subject do
    send_file = file_streamer
    app = Class.new(Grape::API) do
      use Rack::Sendfile
      format :json
      get do
        file send_file
      end
    end

    options = {
      method: 'GET',
      'HTTP_X_SENDFILE_TYPE' => 'X-Accel-Redirect',
      'HTTP_X_ACCEL_MAPPING' => '/accel/mapping/=/replaced/'
    }
    env = Rack::MockRequest.env_for('/', options)
    app.call(env)
  end

  context do
    let(:file_streamer) do
      double(:file_streamer, to_path: '/accel/mapping/some/path')
    end

    it 'contains Sendfile headers' do
      headers = subject[1]
      expect(headers).to include('X-Accel-Redirect')
    end
  end

  context do
    let(:file_streamer) do
      double(:file_streamer)
    end

    it 'not contains Sendfile headers' do
      headers = subject[1]
      expect(headers).to_not include('X-Accel-Redirect')
    end
  end
end
