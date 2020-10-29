# frozen_string_literal: true

require 'spec_helper'

describe Grape::API::Helpers do
  module PatchHelpersSpec
    class PatchPublic < Grape::API
      format :json
      version 'public-v1', using: :header, vendor: 'grape'

      get do
        { ok: 'public' }
      end
    end

    module AuthMethods
      def authenticate!; end
    end

    class PatchPrivate < Grape::API
      format :json
      version 'private-v1', using: :header, vendor: 'grape'

      helpers AuthMethods

      before do
        authenticate!
      end

      get do
        { ok: 'private' }
      end
    end

    class Main < Grape::API
      mount PatchPublic
      mount PatchPrivate
    end
  end

  def app
    PatchHelpersSpec::Main
  end

  context 'patch' do
    it 'public' do
      patch '/', {}, 'HTTP_ACCEPT' => 'application/vnd.grape-public-v1+json'
      expect(last_response.status).to eq 405
    end

    it 'private' do
      patch '/', {}, 'HTTP_ACCEPT' => 'application/vnd.grape-private-v1+json'
      expect(last_response.status).to eq 405
    end

    it 'default' do
      patch '/'
      expect(last_response.status).to eq 405
    end
  end

  context 'default' do
    it 'public' do
      get '/', {}, 'HTTP_ACCEPT' => 'application/vnd.grape-public-v1+json'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ ok: 'public' }.to_json)
    end

    it 'private' do
      get '/', {}, 'HTTP_ACCEPT' => 'application/vnd.grape-private-v1+json'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ ok: 'private' }.to_json)
    end

    it 'default' do
      get '/'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq({ ok: 'public' }.to_json)
    end
  end
end
